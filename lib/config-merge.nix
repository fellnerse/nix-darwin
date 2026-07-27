# Shared home-manager activation helpers for "mutable declarative config":
# a tool's own settings file stays a real, writable file (never a home.file
# store symlink) so the tool's own UI/CLI can keep editing it, while nix still
# gets to declare values that should win on every `darwin-rebuild switch` /
# `home-manager switch`.
#
# Same technique home-manager's own `programs.zed-editor` module uses to keep
# Zed's settings.json mutable (jq `dynamic * static` against a generated JSON
# blob, entryAfter "linkGeneration"/"writeBoundary"), lifted out here so every
# module in this repo (omp.nix, claude.nix, …) shares one implementation
# instead of hand-rolling its own jq/shell-quoting.
#
# Usage from a home-manager module:
#   { pkgs, lib, ... }:
#   let
#     configMerge = import ../lib/config-merge.nix { inherit lib pkgs; };
#   in
#   {
#     home.activation.fooSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] (
#       configMerge.mergeFile {
#         path = "${config.home.homeDirectory}/.foo/settings.yml";
#         # `static` MUST be JSON — always pkgs.formats.json{}.generate, even
#         # when `format` (the *on-disk* codec at `path`) is "yaml"/"toml"/etc.
#         static = (pkgs.formats.json { }).generate "foo-settings.json" fooStaticSettings;
#         format = "yaml";
#       }
#     );
#   }
{ lib, pkgs }:
let
  yq = lib.getExe pkgs.yq-go;
  jq = lib.getExe pkgs.jq;

  # Read `path` off disk as JSON on stdout, regardless of its own on-disk
  # codec: JSON needs no conversion, anything else goes through yq.
  readDynamicJson =
    path: format:
    if format == "json" then
      "cat ${lib.escapeShellArg path}"
    else
      "${yq} -p=${format} -o=json '.' ${lib.escapeShellArg path}";

  # Write merged JSON (on stdin as `$merged`) back to `path` in its native
  # codec: JSON is written as-is, anything else is converted from JSON by yq.
  writeMergedJson =
    path: format:
    if format == "json" then
      ''printf '%s\n' "$merged" > ${lib.escapeShellArg path}''
    else
      ''printf '%s\n' "$merged" | ${yq} -p=json -o=${format} '.' - > ${lib.escapeShellArg path}'';

  preamble = path: ''
    mkdir -p "$(dirname ${lib.escapeShellArg path})"
    [ -e ${lib.escapeShellArg path} ] || printf '{}' > ${lib.escapeShellArg path}
  '';
in
{
  # Deep-merges `static` (a path to a generated JSON file — ALWAYS
  # `(pkgs.formats.json {}).generate`, regardless of `format`) over whatever
  # is currently on disk at `path`, via jq's `*` operator: objects merge
  # recursively, arrays/scalars are replaced wholesale by the right-hand
  # side. `static` wins for every key it declares; any key set interactively
  # (through the tool's own settings UI/CLI) that `static` doesn't mention
  # survives the merge untouched. `format` is only the on-disk codec at
  # `path` ("json" skips the yq round-trip entirely; anything else — "yaml",
  # "toml", … — must be a format `yq` understands).
  mergeFile =
    {
      path,
      static,
      format ? "json",
    }:
    ''
      ${preamble path}
      dynamic="$(${readDynamicJson path format})"
      static="$(cat ${lib.escapeShellArg static})"
      merged="$(${jq} -n '$dynamic * $static' --argjson dynamic "$dynamic" --argjson static "$static")"
      ${writeMergedJson path format}
    '';

  # Forces exactly one dot-path inside `path` to `static`'s value on every
  # activation — "declarative source of truth for this one subtree" — while
  # leaving every other key on disk untouched. Unlike `mergeFile`, values
  # added interactively *inside* that subtree do NOT survive (the whole
  # subtree is replaced, not merged); use `mergeFile` instead if interactive
  # additions inside the managed keys should be preserved. `static` MUST be
  # JSON (`(pkgs.formats.json {}).generate`) regardless of `format`, same as
  # `mergeFile`. `jqPath` is a trusted jq path expression written by the
  # module author (e.g. `.mcpServers`), never user input.
  setPath =
    {
      path,
      jqPath,
      static,
      format ? "json",
    }:
    ''
      ${preamble path}
      dynamic="$(${readDynamicJson path format})"
      static="$(cat ${lib.escapeShellArg static})"
      merged="$(${jq} -n --argjson dynamic "$dynamic" --argjson static "$static" '$dynamic | ${jqPath} = $static')"
      ${writeMergedJson path format}
    '';
}
