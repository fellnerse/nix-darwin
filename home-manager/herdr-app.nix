{
  config,
  lib,
  pkgs,
  ...
}:
# The sheep-themed Herdr desktop app (herdr-app/ in this repo): a theme, the
# bleat, and the `flock` mod that replaces the agents list. Herdr rewrites parts
# of ~/.config/herdr-app itself (shipped layouts, d.ts files, settings.json), so
# only our own files are installed, one by one, and the two files that derive
# from Herdr's are generated on activation.
#
# Copied, not symlinked: Herdr refuses a mod whose modules resolve outside its
# folder, and a link into the Nix store does. So changes to herdr-app/ reach the
# app on the next `mise run user`.
let
  jq = "${pkgs.jq}/bin/jq";
  appHome = "${config.home.homeDirectory}/.config/herdr-app";

  files = [
    "themes/sheep.json"
    "sounds/bleat.wav"
    "layouts/sheep.svg"
    "mods/flock/main.js"
    "mods/flock/sheep.js"
    "mods/flock/mod.json"
  ];

  # sheep layout = Herdr's own `main` layout with the agents list swapped for
  # the flock, rounder pane cards and the sheep theme. Derived (not cloned), so
  # it follows whatever `main` becomes. Fails to write rather than writing a
  # layout without the flock if a Herdr update renames the agents block.
  sheepLayout = ''
    walk(
      if type == "object" and (.content | type) == "object" then
        (if .content.mod == "agents" then .content.mod = "flock" else . end)
        | (if (.content.pane | type) == "object" then .content.pane.radius = 14 else . end)
      else . end
    )
    | .theme = "sheep"
    | .preview = "layouts/sheep.svg"
  '';
in
{
  home.activation.herdrAppSheep = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    app=${lib.escapeShellArg appHome}
    ${lib.concatMapStringsSep "\n" (f: ''
      mkdir -p "$app/${builtins.dirOf f}"
      rm -f "$app/${f}"
      install -m 644 ${../herdr-app + "/${f}"} "$app/${f}"
    '') files}
    main="$app/layouts/main.json"
    if [ -f "$main" ]; then
      tmp="$(mktemp)"
      if ${jq} ${lib.escapeShellArg sheepLayout} "$main" > "$tmp" \
        && ${jq} -e '[.. | .content? | objects | select(.mod == "flock")] | length > 0' "$tmp" > /dev/null; then
        mv "$tmp" "$app/layouts/sheep.json"
      else
        rm -f "$tmp"
        echo "herdr-app: could not derive the sheep layout from layouts/main.json (Herdr changed it?), keeping the old one" >&2
      fi
    else
      echo "herdr-app: $main not there yet, start Herdr once and switch again" >&2
    fi

    # settings.json is the app's own file (zoom, ...): set just the two sound
    # files and leave `enabled` alone, so muting in Settings > Alerts survives.
    settings="$app/settings.json"
    [ -f "$settings" ] || { mkdir -p "$app"; echo '{}' > "$settings"; }
    tmp="$(mktemp)"
    ${jq} '.sounds = ({enabled: true} + (.sounds // {}) + {done: "sounds/bleat.wav", blocked: "sounds/bleat.wav"})' "$settings" > "$tmp" \
      && mv "$tmp" "$settings"
  '';
}
