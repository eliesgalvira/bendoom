{ inputs, ... }:
{
  perSystem = { config, lib, pkgs, system, ... }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.meta) availableOn;
    in {
      packages = {
        bend-web = config.packages.bend.overrideAttrs {
          pname = "bend-web";
          version = "0bafcc5";
          src = inputs.bend-web-src;
          patches = [ ./web-audio.patch ./web-runtime.patch ];
        };
      } // optionalAttrs (availableOn pkgs.stdenv.hostPlatform pkgs.chromium) {
        web = pkgs.callPackage ./web.nix {
          inherit (config.packages.bendoom) iwad;
          game = pkgs.callPackage ./web-game.nix {
            bend = config.packages.bend-web;
            inherit (config.packages) bendoom;
          };
        };
      };
      checks = optionalAttrs (system == "x86_64-linux") {
        web = pkgs.callPackage ./web-check.nix {
          bend = config.packages.bend-web;
          inherit (config.packages) web;
        };
      };
    };
}
