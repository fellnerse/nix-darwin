if status is-interactive
    # Commands to run in interactive sessions can go here
    eval (/opt/homebrew/bin/brew shellenv)
end
# set -x HOMEBREW_BUNDLE_FILE ~/Library/Mobile\ Documents/com\~apple\~CloudDocs/settings/brew/Brewfile

# iterm
test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

# thefuck
thefuck --alias | source

# alises
abbr -a tf terraform
abbr -a tg terragrunt
abbr -a gpt sgpt
abbr -a n nano
abbr -a jwt_iat_exp "jwt -p | jq -s 'select(. != null) | .[1] | {issued_at: (.iat | strftime(\"%Y-%m-%d %H:%M:%S\")), expired_at: (.exp | strftime(\"%Y-%m-%d %H:%M:%S\"))}'"
abbr -a ls eza
abbr -a baobab "GSETTINGS_SCHEMA_DIR=/opt/homebrew/share/glib-2.0/schemas/ baobab"
abbr -a gss "git status -s"
abbr -a lz lazygit

# jetbrains toolbox
export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"

# aws cli
set -x AWS_PROFILE sts
set -x AWS_DEFAULT_PROFILE sts
set -x AWS_REGION eu-central-1
set -x AWS_DEFAULT_REGION eu-central-1

# use nano instead of vi for editor stuff
set -x EDITOR nano

# git diff with delta should be able to use mouse scroll
set -x LESS --redraw-on-quit

# k8s config for SMA
set -x KUBECONFIG ~/.kube/config

# todo ask miguel why I have to write this myself and why nix-your-shell is not doing this
function develop --wraps='nix develop'
  env ANY_NIX_SHELL_PKGS=(basename (pwd))"#"(git describe --tags --dirty) (type -P nix) develop --command fish
end

function git-cleanup-branches
    # Delete local branches that have been merged
    set local_branches (git branch --merged | grep -v '\*' | grep -v 'master' | grep -v 'main')
    if test -n "$local_branches"
        echo $local_branches | xargs -n 1 git branch -d
        echo "Merged local branches have been deleted."
    else
        echo "No merged local branches to delete."
    end

    # Prune remote-tracking branches and delete local branches with no remote
    git fetch --all -p
    set remote_branches (git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {print $1}')
    if test -n "$remote_branches"
        for branch in $remote_branches
            git branch -D $branch
            echo "Deleted branch: $branch"
        end
        echo "Branches with no remote have been deleted."
    else
        echo "No branches with deleted remotes found."
    end
end

# git abbreviations; list of common abbreviations: https://kapeli.com/cheat_sheets/Oh-My-Zsh_Git.docset/Contents/Resources/Documents/index
function __git_default_branch
  # 1) If in a git repo
  if not git rev-parse --git-dir >/dev/null 2>&1
      return 1
  end

  # 2) Try the remote HEAD (respects repo config)
  #    `git symbolic-ref refs/remotes/origin/HEAD` -> refs/remotes/origin/main
  set -l symref (git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  if test -n "$symref"
      # symref is like "origin/main" -> take part after slash
      echo (string split -m1 / -- "$symref")[2]
      return
  end

  # 3) Inspect remote HEAD via ls-remote (works even if symref missing)
  set -l remote_head (git ls-remote --symref --heads origin HEAD 2>/dev/null | awk '/^ref:/ {print $2}')
  if test -n "$remote_head"
      # remote_head looks like "refs/heads/main"
      echo (string replace -r '^refs/heads/' \'\' -- "$remote_head")
      return
  end

  # 4) Fallback: pick first existing of common names
  for candidate in main master trunk default develop
      if git show-ref --verify --quiet "refs/heads/$candidate"
          echo $candidate
          return
      end
  end

  # 5) Last resort: current branch (better than nothing)
  set -l cur (git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if test "$cur" != "HEAD" -a -n "$cur"
      echo $cur
      return
  end

  # 6) Give up silently
  return 1
end
function gcm; git checkout $(__git_default_branch); end
function gll; git pull; end