{
  enable = true;
  user = "private";
  onActivation = {
    # updates homebrew packages on activation,
    # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
    autoUpdate = true;
    upgrade = true;
    cleanup = "uninstall";
  };
  brews = [
    "baobab"
    "docker-credential-helper"
    "glib"
    "mas"
  ];
  casks = [
    # "bitwarden" the cask version does not support fingerprint auth enymore
    "arc"
    "bambu-studio"
    "bruno"
    "crossover"
    "ghostty"
    "imageoptim"
    "jetbrains-toolbox"
    "maccy"
    "macfuse" # Required for sshfs-mac
    "obsidian"
    "signal"
    "slack"
    "spotify"
    "steam"
    "sublime-text"
    "tailscale-app"
    "wave"
  ];
  masApps = {
    "Bitwarden" = 1352778147;
  };
}
