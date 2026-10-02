{ lib, stdenvNoCC, bend, emscripten, bendoom }:

let
  inherit (lib.fileset) toSource unions;
  inherit (lib.meta) getExe;
in
stdenvNoCC.mkDerivation {
  pname = "bendoom-web-game";
  version = "0.1.0";
  src = toSource {
    root = ../.;
    fileset = unions [ ../doom.bend ../src ];
  };
  nativeBuildInputs = [ bend emscripten ];

  buildPhase = /* bash */ ''
    runHook preBuild
    export EM_CACHE=$TMPDIR/emscripten
    export EMCC_CORES=2
    ${getExe bend} doom.bend -o game.c
    mkdir dist
    emcc -std=gnu11 -O2 -pthread -mtail-call game.c \
      -sPROXY_TO_PTHREAD -sPTHREAD_POOL_SIZE=2 -sINITIAL_MEMORY=1073741824 \
      -sENVIRONMENT=web,worker -sEXIT_RUNTIME=1 \
      '-sEXPORTED_RUNTIME_METHODS=["ENV","callMain"]' \
      --preload-file ${bendoom.iwad}@/doom1.wad \
      --preload-file ${bendoom.sounds}@/sounds \
      -o dist/game.js
    runHook postBuild
  '';

  installPhase = /* bash */ ''
    runHook preInstall
    cp -r dist $out
    runHook postInstall
  '';
}
