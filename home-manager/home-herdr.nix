{ ... }:
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
  imports = [
    ./claude.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
