---
title: Homebrew (/opt/homebrew) ownership drift between sefe and private
module: homebrew
tags: [homebrew, permissions, multi-user, macos, git, recovery]
problem_type: system_issue
date: 2026-10-08
---

# Homebrew (`/opt/homebrew`) ownership drift between `sefe` and `private`

## TL;DR

- Homebrew is deliberately owned by the `private` user (see `hosts/mbp/homebrew.nix`), not the primary login user `sefe`. The `brew`/`omp` wrappers in `home-manager/fish.nix` enforce this with `sudo -u private`.
- That wrapper is a **fish abbreviation** — it only applies to an interactive fish shell typing `brew`/`omp` literally. It does **not** cover Homebrew's own auto-update-on-every-command behavior, scripts, non-interactive shells, IDE/extension-triggered brew calls, or a stray `sudo brew ...` typed directly.
- Because `/opt/homebrew` was `775` (group `admin`, group-writable) and `sefe` is also in `admin`, any of those paths could silently write files as `sefe` (or `root`, from a raw `sudo brew`) into a tree that's supposed to be exclusively `private`-owned.
- Symptom: `brew update` fails with `error: insufficient permission for adding an object to repository database .git/objects` / `fatal: failed to write object` — because new loose-object directories under `.git/objects` are owned by `sefe`/`root` with `755` (no group write), which `private` can traverse but not write into.

## Diagnosis

```bash
# confirm ownership drift
find /opt/homebrew -not -user private 2>/dev/null | wc -l
cd /opt/homebrew && find .git -not -user private -exec stat -f '%Su:%Sg %N' {} \; | awk '{print $1}' | sort | uniq -c
```

On 2026-10-08 this found 1,551 files outside `.git` and 82 inside it owned by `sefe` (81) and `root` (1), several of the `.git/objects/xx` subdirectories at `755` instead of the surrounding tree's `775` — exactly enough to block `private` from adding new objects.

## Fix

```bash
sudo chown -R private:admin /opt/homebrew   # repair current drift
sudo chmod -R g-w,o-w /opt/homebrew         # structural guardrail, see below
```

Verify:

```bash
find /opt/homebrew -not -user private 2>/dev/null | wc -l   # should print 0
sudo -u private env HOME=/Users/private HOMEBREW_CACHE=/Users/private/Library/Caches/Homebrew brew update
```

## Prevention

The fish abbreviation alone is not a guardrail — it is convenience that silently does nothing the moment Homebrew is invoked any other way. The `chmod -R g-w,o-w` step above **is** the actual guardrail: it makes `/opt/homebrew` writable only by its owner (`private`), full stop, regardless of which shell, script, or tool tries to write to it.

This does not break `sefe`'s use of already-installed Homebrew binaries (`herdr`, `omp`, `mole`, `baobab`, Homebrew casks, `brew shellenv` on PATH) — all of that only needs read+execute, which group/other still have. It only blocks *writing* (installs/upgrades/`brew update`), which was only ever supposed to happen as `private` anyway.

If this recurs, the drift is almost certainly a new write path that still runs as `sefe`/`root` (e.g. a new launchd agent, a Brewfile-adjacent script, or a GUI app invoking `brew` under the hood) rather than a problem with the permissions fix — re-run the diagnosis commands above to find the specific files and trace back what wrote them (`stat -f '%Sm %Su' <file>` plus timestamps around when the problem started).
