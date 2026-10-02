#!/bin/sh
set -eu

bundle=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
iwad=$bundle/share/doom.wad
sounds=$bundle/share/sounds

run() {
  if [ -f "$bundle/bin/ld.so" ]; then
    "$bundle/bin/ld.so" "$@"
  else
    "$@"
  fi
}

if [ -f "$bundle/bin/ld.so" ]; then
  export ALSA_PLUGIN_DIR="${ALSA_PLUGIN_DIR-$bundle/lib/alsa-lib}"
  export ALSA_CONFIG_DIR="${ALSA_CONFIG_DIR-$bundle/share/alsa}"
  export PIPEWIRE_CONFIG_DIR="${PIPEWIRE_CONFIG_DIR-$bundle/share/pipewire}"
  PIPEWIRE_MODULE_DIR=${PIPEWIRE_MODULE_DIR-$(CDPATH='' cd -- "$bundle/lib/pipewire-0.3" && pwd -P)}
  SPA_PLUGIN_DIR=${SPA_PLUGIN_DIR-$(CDPATH='' cd -- "$bundle/lib/spa-0.2" && pwd -P)}
  export PIPEWIRE_MODULE_DIR SPA_PLUGIN_DIR
fi

decode_recording() {
  if [ -f "$bundle/bin/basenc" ]; then
    run "$bundle/bin/basenc" --base16 -d "$1"
  else
    /usr/bin/xxd -r -p "$1"
  fi
}

run_game() { run "$bundle/bin/game" "$@"; }
