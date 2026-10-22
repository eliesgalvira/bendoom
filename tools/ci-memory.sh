#!/usr/bin/env bash
set -u

snapshot() {
  echo "[ci-memory] $(date -u +%FT%TZ)"
  grep -E '^(MemAvailable|SwapTotal|SwapFree):' /proc/meminfo
  cat /proc/pressure/memory
  echo "[ci-memory] process columns: pid ppid comm rss_KiB vsz_KiB elapsed_seconds"
  local pid rest cgroup directory file
  local -A groups=([/sys/fs/cgroup]=1)
  while read -r pid rest; do
    echo "[ci-memory] process $pid $rest"
    grep -E '^(VmPeak|VmHWM|VmRSS|VmSwap|Threads):' "/proc/$pid/status" || true
    grep -E 'Max (address space|data size|resident set|stack size)' "/proc/$pid/limits" || true
    cgroup=$(awk -F: '$1 == "0" {print $3}' "/proc/$pid/cgroup") || continue
    directory="/sys/fs/cgroup$cgroup"
    while [[ "$directory" == /sys/fs/cgroup/* ]]; do
      groups["$directory"]=1
      directory=${directory%/*}
    done
  done < <(ps -C bun,clang,nix,nix-daemon -o pid=,ppid=,comm=,rss=,vsz=,etimes=)
  for directory in "${!groups[@]}"; do
    echo "[ci-memory] cgroup $directory"
    for file in memory.current memory.peak memory.max memory.high memory.swap.current memory.swap.peak memory.swap.max memory.events memory.pressure; do
      if [[ -r "$directory/$file" ]]; then
        printf '%s ' "$file"
        cat "$directory/$file"
      fi
    done
  done
}

monitor() {
  local sleeper=
  trap '[[ -z "$sleeper" ]] || kill "$sleeper" 2>/dev/null; exit 0' TERM INT
  while true; do
    snapshot
    sleep 30 &
    sleeper=$!
    wait "$sleeper"
  done
}

monitor &
monitor_pid=$!
cleanup() {
  kill "$monitor_pid" 2>/dev/null || true
  wait "$monitor_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
"$@"
status=$?
cleanup
trap - EXIT
snapshot
echo "[ci-memory] command exit $status"
exit "$status"
