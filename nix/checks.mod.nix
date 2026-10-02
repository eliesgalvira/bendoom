{
  perSystem = { config, pkgs, ... }: {
    checks = {
      launchers = pkgs.callPackage ./launchers.nix { };
      proof = pkgs.callPackage ./proof.nix { inherit (config.packages) bend; };
      tests = pkgs.callPackage ./tests.nix {
        inherit (config.packages) bend;
        sounds = config.packages.sounds-freedoom;
      };
    };
  };
}
