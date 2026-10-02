{ lib, stdenv, callPackage, writeShellApplication, coreutils, bend, libx11, alsa-lib, alsa-plugins, iwad
, sounds }:

let
  inherit (lib.lists) optionals singleton;
  inherit (lib.meta) getExe;
  inherit (lib.strings) escapeShellArg optionalString;
  inherit (lib.trivial) readFile;
  inherit (lib.licenses) gpl2Plus;
  inherit (lib.platforms) unix;

  linux = stdenv.hostPlatform.isLinux;
  game = callPackage ./program.nix {
    inherit bend;
    pname = "bendoom-game";
    root = ../doom.bend;
    sources = singleton ../src;
    buildInputs = optionals linux [ libx11 alsa-lib ];
  };
in
writeShellApplication {
  name = "bendoom";
  passthru = { inherit game iwad alsa-plugins; sounds = sounds iwad; };
  runtimeInputs = singleton coreutils;
  text = /* bash */ ''
    iwad=${escapeShellArg iwad}
    sounds=${sounds iwad}
    ${optionalString linux /* bash */ ''
      export ALSA_PLUGIN_DIR=''${ALSA_PLUGIN_DIR-${alsa-plugins}}
    ''}
    run_game() { ${getExe game} "$@"; }
    decode_recording() { basenc --base16 -d "$1"; }
    ${readFile ./launch.sh}
  '';
  meta = {
    description = "Doom, written in Bend 2";
    license = gpl2Plus;
    platforms = unix;
  };
}
