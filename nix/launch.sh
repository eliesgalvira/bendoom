export BENDOOM_IWAD="${BENDOOM_IWAD-$iwad}"

if [ "${RECORD+x}" ]; then
  demo=$RECORD
  recording=$(mktemp -d "$demo.XXXXXX")
  RECORD=$recording/demo.hex
  export RECORD
  trap 'rm -r -- "$recording"' EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
fi
run_game --threads 1 "$@"
if [ "${RECORD+x}" ]; then
  test -s "$RECORD"
  decode_recording "$RECORD" > "$recording/demo.lmp"
  mv -- "$recording/demo.lmp" "$demo"
fi
