if status is-interactive
    # Commands to run in interactive sessions can go here
    eval (/opt/homebrew/bin/brew shellenv)
end
# set -x HOMEBREW_BUNDLE_FILE ~/Library/Mobile\ Documents/com\~apple\~CloudDocs/settings/brew/Brewfile

# iterm
test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

# autojump
[ -f /opt/homebrew/share/autojump/autojump.fish ]; and source /opt/homebrew/share/autojump/autojump.fish

# thefuck
thefuck --alias | source

# alises
abbr -a tf terraform
abbr -a tg terragrunt
abbr -a gpt sgpt
abbr -a n nano
abbr -a jwt_iat_exp "jwt -p | jq -s 'select(. != null) | .[1] | {issued_at: (.iat | strftime(\"%Y-%m-%d %H:%M:%S\")), expired_at: (.exp | strftime(\"%Y-%m-%d %H:%M:%S\"))}'"
abbr -a ls eza
abbr -a cat bat
abbr -a baobab "GSETTINGS_SCHEMA_DIR=/opt/homebrew/share/glib-2.0/schemas/ baobab"

# jetbrains toolbox
export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"

# aws cli
set -x AWS_PROFILE sts
set -x AWS_DEFAULT_PROFILE sts
set -x AWS_REGION eu-central-1
set -x AWS_DEFAULT_REGION eu-central-1

# use nano instead of vi for editor stuff
set -x EDITOR nano

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
