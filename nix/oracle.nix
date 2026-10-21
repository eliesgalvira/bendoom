{ lib, runCommand, nushell, bash, coreutils, freedoom }:

runCommand "bendoom-oracle-tests" {
  nativeBuildInputs = [ nushell bash coreutils ];
  BENDOOM_IWAD = "${freedoom}/share/games/doom/freedoom1.wad";
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../tools/oracle.nu
      ../tools/xvfb.nu
      ../tools/demo.nu
      ../tools/wad.nu
      ../tests/oracle.nu
    ];
  };
} /* bash */ ''
  cp -r "$src" source
  chmod -R u+w source
  cd source
  nu --no-config-file tests/oracle.nu
  touch "$out"
''
