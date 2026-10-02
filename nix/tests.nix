{ lib, llvmPackages_19, bend, bun, alsa-lib, freedoom, sounds }:

let
  inherit (lib.fileset) toSource unions difference;
  inherit (lib.lists) optionals singleton;
  inherit (lib.strings) optionalString;
  inherit (lib.trivial) readFile;
in
llvmPackages_19.stdenv.mkDerivation {
  pname = "bendoom-tests";
  version = "0.1.0";

  src = toSource {
    root = ../.;
    fileset = unions [
      ../src
      (difference ../tests ../tests/launchers.nu)
      ../film.bend
    ];
  };

  nativeBuildInputs = [ bend bun ];
  # tests/game.bend builds the game's loop, whose music links ALSA on
  # Linux.
  buildInputs = optionals llvmPackages_19.stdenv.hostPlatform.isLinux (singleton alsa-lib);

  BENDOOM_IWAD = "${freedoom}/share/games/doom/freedoom1.wad";
  BENDOOM_SOUNDS = sounds;

  buildPhase = /* bash */ ''
    runHook preBuild
    export HOME=$TMPDIR
    ${optionalString llvmPackages_19.stdenv.hostPlatform.isAarch64 /* bash */ ''
      ulimit -S -s 32768
      export BUN_JSC_maxPerThreadStackUsage=16777216
    ''}
    ${readFile ./compile.sh}
    for t in tests/*.bend; do
      name=$(basename $t .bend)
      sed -n 's/^#|//p' $t > $name.want
      compile_bend $t $name ${if llvmPackages_19.stdenv.hostPlatform.isDarwin then "darwin" else "linux"}
      ./$name > $name.native.got
      diff $name.want $name.native.got
      echo "PASS $name native"
      bend $t -o $name.js
      bun $name.js > $name.js.got
      diff $name.want $name.js.got
      echo "PASS $name js"
    done
    runHook postBuild
  '';

  installPhase = /* bash */ ''
    install -Dm644 -t $out *.got
  '';
}
