{
  enable = true;
  # updates homebrew packages on activation,
  # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
  onActivation.autoUpdate = true;
  casks = [
    # "bitwarden" the cask version does not support fingerprint auth enymore
    "signal"
    "arc"
    "bambu-studio"
    "iterm2"
    "whisky"
    "obsidian"
  ];
  masApps = {
    "Bitwarden" = 1352778147;
    "Tailscale" = 1475387142;
  };
}
