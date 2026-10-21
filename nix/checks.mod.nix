{
  perSystem = { config, pkgs, ... }: {
    checks = {
      oracle = pkgs.callPackage ./oracle.nix { };
      launchers = pkgs.callPackage ./launchers.nix { };
      proof = pkgs.callPackage ./proof.nix { inherit (config.packages) bend; };
      tests = pkgs.callPackage ./tests.nix { inherit (config.packages) bend; };
    };
  };
}
