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
    ];
  };

  # Sefe-specific starship settings
  programs.starship.settings = {
    direnv.disabled = true;
    aws.disabled = true;
    gcloud.disabled = true;
    azure.disabled = true;
    docker_context.disabled = true;
    nix_shell.disabled = true;
    line_break.disabled = false;
    directory = {
      truncate_to_repo = true;
    };
  };

  programs.k9s = {
    enable = true;
    # was not able to get it to work with command kubectl, that does not support pipes
    # the plugins location can be found with k9s info
    # logs about plugin failure can be found in the logs (also in k9s info)
    plugin = {
      plugins = {
        jqlogs = {
          shortCut = "Ctrl-L";
          confirm = false;
          description = "Logs (jq)";
          scopes = [
            "pod"
          ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl logs -f --tail=20 "$NAME" -n "$NAMESPACE" --context "$CONTEXT" \
                          | jq -SR '. | try (fromjson| (.record.time.repr) +" " + (.record.level.name) +" ["+ (.record.extra.plant_id) +"|" +(.record.extra.correlation_id) +"] "+ (.record.message ) )' ''
          ];
        };
        # deployment view plugin
        jqlogsd = {
          shortCut = "Ctrl-L";
          confirm = false;
          description = "Logs (jq)";
          scopes = [ "deployment" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl logs -f --tail=20 "deployment/$NAME" -n "$NAMESPACE" --context "$CONTEXT" \
                | jq -SR '. | try (fromjson | (.record.time.repr) +" " + (.record.level.name) + " [" + (.record.extra.plant_id) + "|" + (.record.extra.correlation_id) + "] " + (.record.message)) catch .'
            ''
          ];
        };
        # service view plugin
        jqlogss = {
          shortCut = "Ctrl-L";
          confirm = false;
          description = "Logs (jq)";
          scopes = [ "service" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl logs -f --tail=20 "service/$NAME" -n "$NAMESPACE" --context "$CONTEXT" \
                | jq -SR '. | try (fromjson | (.record.time.repr) +" " + (.record.level.name) + " [" + (.record.extra.plant_id) + "|" + (.record.extra.correlation_id) + "] " + (.record.message)) catch .'
            ''
          ];
        };
      };
    };
  };

  programs.uv.enable = true;
  programs.neovim.enable = true;
  programs.fd.enable = true;
  programs.ripgrep.enable = true;
}
