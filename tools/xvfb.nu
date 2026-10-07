# A private X server for a tool's windows. Xvfb picks a free display and
# writes its number, so runs side by side never share one, and nothing
# shows on the desktop. Sourced by tools/listen.nu, tools/oracle.nu and
# tools/portable-smoke.nu.

# Waits until a closure holds, a tenth of a second at a time.
def wait-for [tries: int, ready: closure, message: string] {
  for _ in 0..<$tries { if (do $ready) { return }; sleep 100ms }
  error make {msg: $message}
}

# Xvfb started as a job described by dir, its output there, and its
# DISPLAY once it is up. Killing the jobs described by dir stops it.
def xvfb [dir: path, size: string]: nothing -> string {
  let file = $dir | path join display
  job spawn --description $dir { ^Xvfb -displayfd 1 -screen 0 $"($size)x24" o> $file e> ($dir | path join xvfb.log) } | ignore
  wait-for 100 { ($file | path exists) and ((open --raw $file | str trim) != "") } "Xvfb did not start"
  $":(open --raw $file | str trim)"
}
