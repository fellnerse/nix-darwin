{
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./common.nix ];

  home = {
    username = "sefe";
    homeDirectory = "/Users/sefe";
    stateVersion = "24.05";
    packages = with pkgs; [
      # teams
      sops
      kubectl
      k9s
    ];
  };

  # Sefe-specific starship settings
  programs.starship.settings = {
    aws.disabled = true;
    gcloud.disabled = true;
    azure.disabled = true;
    docker_context.disabled = true;
    nix_shell.disabled = true;
    line_break.disabled = false;
    directory = {
      truncate_to_repo = true;
    };
    kubernetes = {
      disabled = false;
    };
  };

  # Sefe-specific git config
  programs.git = {
    userName = "sefe 💯";
    userEmail = "sefe@netlight.com"; # Replace with actual email
  };
  # overwrite in client projects like this:
  # shellHook = ''
  #  # Project-specific git config (overrides home-manager defaults)
  #  git config user.name "Client Developer"
  #  git config user.email "dev@client.com"
  #  ...
  #  ''
}
