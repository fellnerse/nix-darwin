{
  enable = true;
  # updates homebrew packages on activation,
  # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
  onActivation.autoUpdate = true;
  casks = [
    # "bitwarden" the cask version does not support fingerprint auth enymore
    "signal"
    "arc"
  ];
  masApps = {
    "Bitwarden" = 1352778147;
    "ExcalidrawZ" = 6636493997;
  };
}
