{ lib, runCommand, bend, emscripten, nodejs, playwright-driver, chromium, web }:

let
  inherit (lib.meta) getExe;
in
runCommand "bendoom-web-check" {
  nativeBuildInputs = [ bend emscripten nodejs ];
  CHROMIUM = getExe chromium;
  PLAYWRIGHT_DRIVER = playwright-driver;
} /* bash */ ''
  export EM_CACHE=$TMPDIR/emscripten
  export EMCC_CORES=2
  export XDG_CACHE_HOME=$TMPDIR/cache
  export XDG_CONFIG_HOME=$TMPDIR/config
  mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
  mkdir site
  cp -r ${web}/. site/
  cp ${../tests/web/audio.html} site/audio-test.html
  bend ${../tests/web/audio.bend} -o audio.c
  emcc -std=gnu11 -O2 -pthread -mtail-call audio.c \
    -sPROXY_TO_PTHREAD -sPTHREAD_POOL_SIZE=2 -sINITIAL_MEMORY=1073741824 \
    -sENVIRONMENT=web,worker -sEXIT_RUNTIME=1 -o site/audio-test.js
  node ${../tools/web-check.cjs} site
  touch $out
''
