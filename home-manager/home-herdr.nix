{ pkgs, ... }:
{
  # herdr is the Debian LXC (VMID 101, PVE) running the coding-agent runtime -
  # see docs/infrastructure/herdr-server.md. No nix-darwin/NixOS here, just a
  # standalone home-manager profile for root (everything on this box runs as
  # root today). claude.nix is a pure config-file generator (no launchd, no
  # homebrew), so it's safe to reuse as-is on Linux.
  #
  # omp.nix is intentionally NOT imported here: its models.yml/config.yml are
  # sefe/private-scoped (personal provider config), and herdr's own
  # /root/.omp/agent/* is managed manually today - see the runbook. Pulling
  # omp.nix in would overwrite that with the shared defaults.
  #
  # fish.nix is safe to reuse as-is: its one macOS-only line (Homebrew
  # shellenv) is guarded to no-op when /opt/homebrew doesn't exist.
  imports = [
    ./claude.nix
    ./fish.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "24.05";
    packages = with pkgs; [
      nix-your-shell
      unstable.antigravity-cli
      nixd # nix language server
      nixfmt # nix formatter
      gh
      unstable.mise
      pre-commit
    ];
  };

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      direnv.disabled = false;
      git_commit.only_detached = false;
      time.disabled = false;
      status.disabled = false;
      sudo.disabled = false;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings = {
      # Same identity as the "private" mac profile - herdr is personal infra.
      user = {
        name = "fellnerse 💯";
        email = "hey@sebastianfellner.de";
      };
      alias.s = "status -s";
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      init.defaultBranch = "main";
      diff.algorithm = "histogram";
      diff.colorMoved = "plain";
      diff.mnemonicPrefix = "true";
      diff.renames = "true";
      push.default = "simple";
      push.autoSetupRemote = "true";
      push.followTags = "true";
      fetch.prune = "true";
      fetch.pruneTags = "true";
      fetch.all = "true";
      help.autocorrect = "prompt";
      commit.verbose = "true";
      rerere.enabled = "true";
      rerere.autoupdate = "true";
      core.excludesfile = "~/.gitignore";
      rebase.autoSquash = "true";
      rebase.autoStash = "true";
      rebase.updateRefs = "true";
    };
  };

  programs.eza = {
    enable = true;
    icons = "always";
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
    };
  };

  programs.fzf.enable = true;
  programs.jq.enable = true;

  programs.autojump = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.lazygit.enable = true;
}
