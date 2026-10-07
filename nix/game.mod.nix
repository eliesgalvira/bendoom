{
  perSystem = { config, pkgs, ... }:
    let
      inherit (config.packages) bend;
      wads = pkgs.callPackage ./wads.nix { };
      freedoom = "${wads.freedoom}/share/games/doom/freedoom1.wad";
      shareware = "${wads.doom1}/share/games/doom/doom1.wad";
      alsa-plugins = pkgs.callPackage ./audio-plugins.nix { };
    in {
      packages = {
        bendoom = pkgs.callPackage ./bendoom.nix { inherit bend alsa-plugins; iwad = shareware; };
        film = pkgs.callPackage ./film.nix { inherit bend; iwad = shareware; };
        default = config.packages.bendoom;
        doom1-wad = wads.doom1;
        bendoom-freedoom = config.packages.bendoom.override { iwad = freedoom; };
        film-freedoom = config.packages.film.override { iwad = freedoom; };
      };

      apps.default = {
        type = "app";
        program = "${config.packages.bendoom}/bin/bendoom";
      };
    };
}
