{
  perSystem = { config, pkgs, ... }:
    let
      inherit (config.packages) bend;
      wads = pkgs.callPackage ./wads.nix { };
      freedoom = "${wads.freedoom}/share/games/doom/freedoom1.wad";
      shareware = "${wads.doom1}/share/games/doom/doom1.wad";
      render = args: iwad: pkgs.callPackage ./render.nix (args // { inherit bend iwad; });
      sounds = render {
        pname = "bendoom-sounds";
        root = ../sounds.bend;
        sources = [
          ../src/angle.bend ../src/bytes.bend ../src/fixed.bend ../src/sfx.bend
          ../src/sfx_taps.bend ../src/sound.bend ../src/vec.bend ../src/wad.bend
        ];
      };
      alsa-plugins = pkgs.callPackage ./audio-plugins.nix { };
    in {
      packages = {
        bendoom = pkgs.callPackage ./bendoom.nix { inherit bend sounds alsa-plugins; iwad = shareware; };
        film = pkgs.callPackage ./film.nix { inherit bend sounds; iwad = shareware; };
        default = config.packages.bendoom;
        sounds = sounds shareware;
        doom1-wad = wads.doom1;
        bendoom-freedoom = config.packages.bendoom.override { iwad = freedoom; };
        film-freedoom = config.packages.film.override { iwad = freedoom; };
        sounds-freedoom = sounds freedoom;
      };

      apps.default = {
        type = "app";
        program = "${config.packages.bendoom}/bin/bendoom";
      };
    };
}
