---
title: How to reclaim disk space on this machine (and how not to)
module: nix-gc
tags: [nix, garbage-collection, disk-space, macos, etc-static, gcroots, recovery]
problem_type: system_issue
date: 2026-10-02
---

# How to reclaim disk space on this machine (and how not to)

## TL;DR

1. **Check APFS local snapshots first.** After a macOS major upgrade they are almost always the biggest consumer on this machine, and they are free to delete.
2. **Measure before deleting.** The Nix store is *not* where the space went — it is under 10% of usage.
3. **Never run `nix-collect-garbage -d`** (that is what `mise run gc` currently does — see [Prevention](#prevention)).
4. **Run the `/etc/static` drift guard before any Nix GC.** Thirty seconds of checking prevents a broken shell.
5. If GC refuses to run because of `chmod ... Operation not permitted`, the fix is a *scoped* chmod on a single store path, not a store-wide one.

## Why this doc exists

On 2026-10-01, an aggressive Nix GC run (chasing a 98%-full disk) deleted the `etc` store path that `/etc/static` was pointing at. That single dangling symlink took out every file nix-darwin manages in `/etc` — 21 of them, including `/etc/fish/config.fish`, `/etc/zshrc`, `/etc/bashrc`, `/etc/nix/nix.conf`, `/etc/shells` and `/etc/pam.d/sudo_local`.

Visible damage: login shells lost every Nix path (so `fzf`, `nix-your-shell`, `autojump` all vanished), flakes turned off (`experimental Lix feature 'nix-command' is disabled`), and Touch ID for `sudo` stopped working. On top of that, the GC deleted *every* old generation, so there was no rollback to fall back on.

The painful part: the whole Nix store was only **36 GB of the 448 GB in use**. The GC could never have solved the disk problem it was run to solve. That is the mistake this doc exists to prevent.

## Step 0: pre-flight guard (run this before *any* Nix GC)

`/etc/static` is **not** a registered GC root — `/nix/var/nix/gcroots` contains only `auto/`, `current-system` and `per-user`. The `etc` path it points at survives GC only because the *registered* system generation references it. If `/etc` has drifted out of sync with the system profile, that `etc` has no root, and a GC run will delete it out from under the live system.

```bash
# must print OK before you garbage-collect anything
[ "$(readlink /etc/static)" = "$(readlink -f /run/current-system/etc)" ] \
  && echo OK || echo "DRIFT — fix before GC"
```

If it prints `DRIFT`, repair `/etc` first with the [recovery procedure](#recovery-nix-gc-broke-etc) below, then re-check before collecting.

Drift happens when activation runs from a system build that was never registered in `/nix/var/nix/profiles/system` — an interrupted `darwin-rebuild switch`, or a `result/activate` run by hand. Note that `mise run check` is *safe* here: `darwin-rebuild check` exits at the `checkActivation` guard before it ever touches `/etc`.

## Step 1: measure before deleting

Start with the volume-level view, which is instant and accounts for snapshots that `du` cannot see:

```bash
df -h /
diskutil apfs list | grep -iE "Capacity|Snapshot|Volume"
tmutil listlocalsnapshots /
```

Then drill into the filesystem. Depth-limited, with `-x` to stay on one filesystem, keeps this from taking forever:

```bash
du -xh -d 1 /Users 2>/dev/null    | sort -rh | head
du -xh -d 1 ~ 2>/dev/null         | sort -rh | head -15
du -xh -d 1 ~/Library 2>/dev/null | sort -rh | head -15
du -sxh /nix/store                                       # how much Nix even owns
```

Note: `du -xh -d 1 /` needs `sudo` to be meaningful, and `sudo -n` will silently produce nothing if you have no cached credential — check for empty output rather than assuming the disk is empty.

**Measured baseline, 2026-10-02** (461 GiB disk, 448 GiB used, 14 GiB free):

| Location | Size |
|---|---|
| APFS Data volume, total consumed | 396 GB (decimal, per `diskutil`) |
| `/Users` | 145 GiB (`sefe` 89 GiB, `private` 56 GiB) |
| `/nix/store` | 36 GiB |
| `/Applications` | 26 GiB |
| `~/Library/Application Support` | 28 GiB |
| `~/Library/Caches` | 3.5 GiB (Homebrew 1.5 GiB, Spotify 1.1 GiB, JetBrains 554 MiB) |

**Nix was 8% of usage.** Live files across `/Users` and `/Applications` come to roughly 171 GiB, leaving well over 200 GiB on the Data volume unaccounted for by any directory — which is the signature of APFS snapshots holding onto deleted data. Go to Step 2, not to Nix.

## Step 2: delete stale APFS local snapshots (the usual culprit)

Snapshots pin every block that existed when they were taken, so a snapshot from before a large upgrade or cleanup can hold hundreds of gigabytes that no longer appear in any directory listing. `du` cannot see this space; only the volume-level view can.

As of 2026-10-02 this machine held four:

```
com.apple.TimeMachine.2026-09-23-114736.local (dataless)
com.apple.os.update-5203530F8BB20B9D...
com.apple.os.update-9CFA342F3FC2731D...
com.apple.os.update-MSUPrepareUpdate
```

The three `com.apple.os.update-*` entries are leftovers from the macOS 27 upgrade on 2026-10-01. They exist so the upgrade can be rolled back; once the new OS boots and works, they are dead weight. This is very likely the recurring cause of "the disk is full again" on this machine — every major macOS upgrade creates them.

```bash
# inspect first
tmutil listlocalsnapshots /

# delete one by name (safest — pass the name without the leading
# com.apple.TimeMachine. prefix for TM snapshots, full name for os.update)
sudo tmutil deletelocalsnapshots <snapshot-name>

# or drop every local snapshot for the volume
sudo tmutil deletelocalsnapshots /

# then re-measure
df -h /
```

Deleting local snapshots costs you only local point-in-time rollback; it does not touch your files or any Time Machine backups already written to an external/network destination. Re-measure before doing anything to Nix — on these numbers this step alone should resolve the disk pressure.

## Step 3: reclaim Nix space safely

Only worth doing once you have confirmed Nix is actually a meaningful share of the usage.

**The safe commands:**

```bash
# 1. Keep a rollback window. 14d is a sane floor; never use bare -d.
sudo nix-collect-garbage --delete-older-than 14d

# 2. Collect unreachable paths without touching any generation.
nix-store --gc

# 3. Deduplicate identical files via hardlinks (already automatic here,
#    but safe to force).
nix-store --optimise
```

**Within Nix, the biggest win on this machine is stale `.direnv` GC roots.** There are 161 live auto-roots (plus 112 dead ones, which are harmless — Nix ignores them), and the overwhelming majority are `.direnv/flake-inputs` symlinks inside project directories, including throwaway worktrees:

```bash
# what is pinning the store, and from where
nix-store --gc --print-roots | grep -v '^/proc' | sort

# group auto-roots by owning directory
for l in /nix/var/nix/gcroots/auto/*; do readlink "$l"; done \
  | sed 's|/\.direnv/.*|/.direnv|' | sort | uniq -c | sort -rn | head -20
```

Each live `.direnv` pins an entire flake closure. Deleting `.direnv` in projects you are done with (especially abandoned worktrees under `.delta/worktrees/`, `opencode/worktree/`, and anything named `delete-me`) releases those closures, after which `nix-store --gc` can actually reclaim them. Re-entering the project just rebuilds `.direnv`, so this is cheap to undo.

**Never run these:**

| Command | Why not |
|---|---|
| `nix-collect-garbage -d` | Deletes every old generation of every reachable profile. Destroys rollback, and deletes any `etc` that a drifted `/etc/static` depends on. This is what broke the machine on 2026-10-01. |
| `nix-env --delete-generations old` | Same class of problem for the user profile — no rollback left. |
| `mise run gc` | Safe as of 2026-10-02 — it was rewritten to self-heal `/etc/static` and keep 14 days of generations. See [Prevention](#prevention). |

The declarative weekly GC in `hosts/mbp/configuration.nix` is fine as written — it uses `--delete-older-than 7d`, which preserves a rollback window. The danger is the manual `mise` task, not the scheduled job.

## The `chmod: Operation not permitted` wall

GC can abort with zero paths deleted:

```
error: chmod '<file>' in directory '/nix/store/.../<App>.app/...': Operation not permitted
```

**Mechanism.** When macOS runs a GUI `.app` bundle — particularly one holding TCC privacy grants, like a menu-bar monitor such as Stats.app — TCC and Gatekeeper attach a `com.apple.macl` extended attribute to the bundle. Store paths are read-only (`0555` dirs, `0444` files), so when `nix-daemon` deletes a tree it calls `fchmodat(…, mode | 0700, 0)` on any directory lacking write permission. Because `com.apple.macl` is present and the daemon runs under `launchd` without Full Disk Access, the kernel returns `EPERM`. `deletePath` skips `fchmodat` entirely when a directory already has `u+w`, and plain `unlink`/`rmdir` are not blocked once parents are writable — which is why pre-granting write permission works.

**Correct workaround.** Scope it to the one path named in the error, and delete it immediately so you never leave a mutated path sitting in the store:

```bash
sudo chmod -R u+w /nix/store/<hash>-<name>
sudo nix-store --delete /nix/store/<hash>-<name>
```

Then continue with the safe GC commands from Step 3.

**Do not** run `chmod -R` across `/nix/store` or across a path you have not confirmed is garbage. The store is supposed to be immutable; a live path left world-writable is a real integrity problem. If `nix-store --delete` refuses because the path is still referenced, you have chmod'd something live — restore it with:

```bash
sudo nix-store --repair-path /nix/store/<hash>-<name>
```

Granting Full Disk Access to `nix-daemon` would avoid the `EPERM` altogether in principle, but the daemon binary lives at a store path that changes on every Nix upgrade, so the TCC grant does not survive. Untested here; the scoped chmod is the pragmatic route.

## Recovery: Nix GC broke `/etc`

**Symptoms.** A fresh login shell cannot find any Nix binary (`fish: Unknown command: nix-your-shell`, `fzf was not found in path`); `nix` reports `experimental Lix feature 'nix-command' is disabled`; Touch ID no longer works for `sudo`.

**Confirm it:**

```bash
ls -l /etc/static                              # target missing from the store?
find /etc/ -maxdepth 3 -type l ! -exec test -e {} \; -print   # dangling links
```

Note the trailing slash on `/etc/` — `/etc` is itself a symlink to `private/etc`, and `find` will not descend without it.

**Fix.** The `etc` for the registered generation is almost always still in the store, so this is a one-liner. Flakes are disabled at this point, so the relink *must* come before any rebuild:

```bash
sudo ln -sfn "$(readlink -f /run/current-system/etc)" /etc/static
```

Open a fresh terminal — PATH, flakes and Touch ID sudo all come back, because every dangling link points into `/etc/static` and now resolves again. Then run a real switch so the on-disk state and the system profile agree and the `etc` is properly GC-rooted:

```bash
cd ~/.config/nix-darwin && ~/.nix-profile/bin/mise run system
```

Use the absolute path to `mise`: it only exists at `~/.nix-profile/bin/mise`, which is not on `PATH` until the relink lands.

## Prevention

Make `mise run gc` non-destructive. Current task in `.mise.toml`:

```toml
[tasks.gc]
run = """
nix-env --delete-generations old
nix-store --gc
nix-collect-garbage -d
"""
```

**This has been fixed** (2026-10-02). The task now repairs the drift instead of merely detecting it, by performing the same `/etc/static` relink that `darwin-rebuild` activation does — idempotent, a no-op on a healthy system, and it needs no build or network, unlike running `mise run system` first:

```toml
[tasks.gc]
description = "Garbage collect Nix store (keeps 14d of generations)"
run = """
sudo ln -sfn "$(readlink -f /run/current-system/etc)" /etc/static
sudo nix-collect-garbage --delete-older-than 14d
nix-env --delete-generations 14d
nix-env -p ~/.local/state/nix/profiles/home-manager --delete-generations 14d
nix-store --gc
"""
```

Two notes on that: the relink makes the 2026-10-01 failure mode structurally impossible rather than guarded against, and the two `nix-env` lines are required because `nix-collect-garbage` only walks `/nix/var/nix/profiles` — the standalone home-manager profiles under `~/.local/state/nix/profiles` would otherwise keep pinning closures forever.

Running `mise run system` before `mise run gc` achieves the same guarantee and is also correct, just heavier: a switch writes the system profile *before* activating, so the current generation is always rooted and `/etc` always in sync.

And the habit that matters most: **measure first.** A 98%-full disk on this machine is far more likely to be APFS local snapshots left by a macOS upgrade — or `~/Library/Application Support`, container images and build caches — than the 36 GiB Nix store.
