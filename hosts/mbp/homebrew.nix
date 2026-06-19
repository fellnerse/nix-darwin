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
  # NOTE: Do NOT re-add `masApps = { ... }` / the `mas` brew here.
  # Mac App Store apps (Bitwarden, WhatsApp, Windows App, WireGuard, Slack, ...)
  # are intentionally managed manually via the App Store. `mas` integration kept
  # breaking `darwin-rebuild switch` on a regular basis:
  #   - "Failed to change ownership ... Operation not permitted" on
  #     root-owned/protected apps (Microsoft Office, AdGuard, etc.)
  #   - mas-installed apps clashing with the same app as a cask (Slack), leaving
  #     a root-owned /Applications/*.app that blocked cask upgrades
  #   - flaky "Failed to find pkg to update" errors that needed manual retries
  # The manual App Store workflow is boring but reliable. Leave it that way.
}
