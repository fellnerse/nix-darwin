{
  enable = true;
  user = "private";
  onActivation = {
    # updates homebrew packages on activation,
    # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
    autoUpdate = true;
    upgrade = true;
    cleanup = "uninstall";
    # brew bundle install --cleanup now requires --force in newer Homebrew versions
    extraFlags = [ "--force" ];
  };
  brews = [
    "baobab"
    "docker-credential-helper"
    "glib"
    "mas"
    "mole"
  ];
  casks = [
    # "bitwarden" the cask version does not support fingerprint auth enymore
    "arc"
    # "bambu-studio" This is super unreliable with all the updates the app wants to install itself
    "bruno"
    "crossover"
    "ghostty"
    "imageoptim"
    "jetbrains-toolbox"
    "maccy"
    "obsidian"
    "signal"
    "slack"
    "spotify"
    "steam"
    "sublime-text"
    "tailscale-app"
  ];
  masApps = {
    "Bitwarden" = 1352778147;
    "Slack" = 803453959;
    "WhatsApp" = 310633997;
    "Windows App" = 1295203466;
    "WireGuard" = 1451685025;
  };
}
