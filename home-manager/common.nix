{ pkgs, ... }:
{
  imports = [
    ./fish.nix
    ./zed.nix
    ./claude.nix
    ./omp.nix
  ];

  # Common packages
  home.packages = with pkgs; [
    nix-your-shell
    shell-gpt
    unstable.gemini-cli
    unstable.uv
    unstable.ty
    nixd # nix language server used by zeditor
    nixfmt # nix formatter used by zeditor
    stats # shows networking stats in status bar
    gh
    mise
    pre-commit
    glab
  ];

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

  programs.ssh = {
    enable = true;
    package = pkgs.openssh;
    enableDefaultConfig = false;
    settings = {
      "Host pve.local" = {
        User = "root";
      };
      "Host homeassistant.local" = {
        User = "root";
      };
      # Tailscale hostname for HA - works from anywhere
      "Host homeassistant.tail" = {
        HostName = "homeassistant.tail401ae4.ts.net";
        User = "root";
      };
      # PVE via Tailscale -> HA jump host - works from anywhere
      "Host pve.tail" = {
        HostName = "pve.local";
        User = "root";
        ProxyJump = "homeassistant.tail";
      };
      # herdr LXC container (101) on PVE - agent runtime, DHCP so go via mDNS.
      # Lost every key here? `pct enter 101` on the pve host gives a root shell
      # without credentials (pve itself via its web UI or physical console).
      "Host herdr.local" = {
        User = "root";
      };
      # herdr is its own Tailscale node, so no jump host needed - works from anywhere
      "Host herdr.tail" = {
        HostName = "herdr.tail401ae4.ts.net";
        User = "root";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    # configs from here: https://blog.gitbutler.com/how-git-core-devs-configure-git/
    settings = {
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
      fetch.all = "true"; # why the hell not?
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

  programs.firefox = {
    enable = true;
  };

  programs.zellij = {
    enable = true;
    settings = {
      web_server = true;
    };
  };

  # Stats: Menu bar app that runs silently in the background
  # Launched directly via binary with ProcessType = "Interactive" to enable GUI interaction
  # KeepAlive.SuccessfulExit = false restarts if it crashes, ThrottleInterval prevents rapid restarts
  # LaunchOnlyOnce + delay wrapper ensures GUI session is ready before starting
  launchd.agents.stats = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "sleep 5 && exec ${pkgs.stats}/Applications/Stats.app/Contents/MacOS/Stats"
      ];
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
      };
      ThrottleInterval = 30;
      ProcessType = "Interactive";
    };
  };

  # Ghostty: Terminal app with hotkey window support
  # Must use /usr/bin/open with -g flag (background) instead of direct binary launch
  # Opens an initial window but keeps app in background for hotkey functionality
  # Direct binary launch fails on macOS; -j flag hides app too much and breaks hotkey
  launchd.agents.ghostty = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-a"
        "/Applications/Ghostty.app"
      ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

}
