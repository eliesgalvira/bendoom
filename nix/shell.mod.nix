{
  perSystem = { config, lib, pkgs, ... }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.lists) optionals;
    in {
      devShells.default = pkgs.mkShell ({
        BENDOOM_IWAD = config.packages.bendoom-freedoom.iwad;

        packages = [
          config.packages.bend
          pkgs.bun
          pkgs.nushell
          pkgs.llvmPackages_19.clang
          pkgs.jujutsu
          pkgs.chocolate-doom
          pkgs.xorg.xorgserver
          pkgs.xdotool
          pkgs.pulseaudio
          pkgs.ffmpeg-headless
        ];

        buildInputs = optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libx11 pkgs.alsa-lib ];
      } // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        ALSA_PLUGIN_DIR = config.packages.bendoom-freedoom.alsa-plugins;
      });
    };
}
