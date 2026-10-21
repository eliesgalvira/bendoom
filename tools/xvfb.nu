# A private X server for a tool's windows. Xvfb picks a free display and
# writes its number, so runs side by side never share one, and nothing
# shows on the desktop. Sourced by tools/listen.nu, tools/oracle.nu and
# tools/portable-smoke.nu.

# Waits until a closure holds, a tenth of a second at a time.
def wait-for [tries: int, ready: closure, message: string] {
  for _ in 0..<$tries { if (do $ready) { return }; sleep 100ms }
  error make {msg: $message}
}

# Process output and exit status survive background-job completion.
def process-start [dir: path, name: string, command: closure] {
  job spawn --description $dir {
    let stdout = $dir | path join $'($name).out'
    let stderr = $dir | path join $'($name).err'
    let status = try { do $command o> $stdout e> $stderr; 0 } catch {|e|
      $e.msg | save --append $stderr
      $e.exit_code? | default 127
    }
    $status | into string | save --force ($dir | path join $'($name).pending')
    mv ($dir | path join $'($name).pending') ($dir | path join $'($name).status')
  } | ignore
}

def process-status [dir: path, name: string]: nothing -> bool {
  let file = $dir | path join $'($name).status'
  if not ($file | path exists) { return false }
  let status = open --raw $file | into int
  if $status != 0 {
    let diagnostic = [out err] | each {|suffix| open --raw ($dir | path join $'($name).($suffix)') } | str join (char newline) | str trim
    error make {msg: $'($name) exited with status ($status): ($diagnostic)'}
  }
  true
}

def process-wait [dir: path, name: string, timeout: duration] {
  wait-for (($timeout / 100ms | math ceil | into int) + 1) { process-status $dir $name } $'($name) timed out after ($timeout)'
}

def process-running [dir: path, name: string] {
  if (process-status $dir $name) { error make {msg: $'($name) exited before it was ready'} }
}

# Let jobs finish their log/status writes before their directory is removed.
def process-stop [dir: path] {
  wait-for 100 {
    let jobs = job list | where description == $dir
    if ($jobs | is-empty) { return true }
    for pid in ($jobs | get pids | flatten) { kill --force --quiet $pid }
    false
  } "tool processes did not stop"
}

# Xvfb started as a job described by dir, its output there, and its DISPLAY.
def xvfb [dir: path, size: string]: nothing -> string {
  let file = $dir | path join Xvfb.out
  process-start $dir Xvfb { ^Xvfb -displayfd 1 -screen 0 $"($size)x24" }
  wait-for 100 {
    process-running $dir Xvfb
    ($file | path exists) and ((open --raw $file | str trim) =~ '^[0-9]+$')
  } "Xvfb did not start"
  $":(open --raw $file | str trim)"
}
