{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    shellAbbrs = {
      n = "nano";
      jwt_iat_exp = "jwt -p | jq -s 'select(. != null) | .[1] | {issued_at: (.iat | strftime(\"%Y-%m-%d %H:%M:%S\")), expired_at: (.exp | strftime(\"%Y-%m-%d %H:%M:%S\"))}'";
      ls = "eza";
      baobab = "GSETTINGS_SCHEMA_DIR=/opt/homebrew/share/glib-2.0/schemas/ baobab";
      gss = "git status -s";
      lz = "lazygit";
      zl = "zellij";
    };

    shellInit = ''
      # JetBrains Toolbox
      set -gx PATH "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" $PATH

      # Editor
      set -gx EDITOR nano

      # git diff with delta should be able to use mouse scroll
      set -gx LESS --redraw-on-quit

      # k8s config
      set -gx KUBECONFIG ~/.kube/config
    '';

    interactiveShellInit = ''
      # Homebrew
      eval (/opt/homebrew/bin/brew shellenv)

      # nix-your-shell
      nix-your-shell fish | source
    '';

    functions = {
      git-cleanup-branches = {
        body = ''
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
        '';
      };
    };

    plugins = [
      {
        name = "fish-completion-sync";
        src = pkgs.fetchFromGitHub {
          owner = "pfgray";
          repo = "fish-completion-sync";
          rev = "f75ed04e98b3b39af1d3ce6256ca5232305565d8";
          sha256 = "0q3i0vgrfqzbihmnxghbfa11f3449zj6rkys4vpncdmzb18lqsy2";
        };
      }
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
  };
}
