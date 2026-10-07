{ inputs, ... }:
{
  perSystem = { config, lib, pkgs, system, ... }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (lib.meta) availableOn;
      webFor = bendoom: pkgs.callPackage ./web.nix {
        inherit (bendoom) iwad;
        game = pkgs.callPackage ./web-game.nix {
          bend = config.packages.bend-web;
          inherit bendoom;
        };
      };
    in {
      packages = {
        bend-web = config.packages.bend.overrideAttrs {
          pname = "bend-web";
          version = "0bafcc5";
          src = inputs.bend-web-src;
          patches = [ ./web-audio.patch ./web-runtime.patch ];
        };
      } // optionalAttrs (availableOn pkgs.stdenv.hostPlatform pkgs.chromium) {
        web = webFor config.packages.bendoom;
      };
      checks = optionalAttrs (system == "x86_64-linux") {
        web = pkgs.callPackage ./web-check.nix {
          bend = config.packages.bend-web;
          web = webFor config.packages.bendoom-freedoom;
        };
      };
    };
}
