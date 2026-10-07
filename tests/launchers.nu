use std/assert

def executable [file: path, text: string] {
  $text | save --force $file
  ^chmod +x $file
}

def recording [root: path, shell: string] {
  let dir = $root | path join $shell
  mkdir $dir
  let demo = $dir | path join 'saved game.lmp'
  let launcher = $dir | path join launcher.sh
  let shared = open --raw nix/launch.sh
  for scenario in [startup-failure conversion-failure interrupted empty success] {
    'previous recording' | save --force $demo
    let game = match $scenario {
      startup-failure => 'return 7'
      interrupted => 'printf 6d > "$RECORD"; kill -INT "$$"'
      empty => 'true'
      _ => 'printf 6d80 > "$RECORD"'
    }
    let decoder = if $scenario == conversion-failure {
      'printf partial; return 8'
    } else {
      'basenc --base16 --decode "$1"'
    }
    [
      'set -eu'
      'iwad=unused'
      ('run_game() { ' + $game + '; }')
      ('decode_recording() { ' + $decoder + '; }')
      $shared
    ] | str join (char newline) | save --force $launcher
    let result = with-env {RECORD: $demo} { ^$shell $launcher | complete }
    if $scenario == success {
      assert equal $result.exit_code 0
      assert equal (open --raw $demo | into binary) 0x[6d80]
    } else {
      assert ($result.exit_code != 0) $'($shell): ($scenario) should fail'
      assert equal (open --raw $demo) 'previous recording' $'($shell): ($scenario) replaced the saved demo'
    }
    assert equal (glob ($dir | path join 'saved game.lmp.*') | length) 0
  }
  print $'PASS ($shell): failed recordings preserve the destination; successful recordings replace it'
}

def installer [root: path, shell: string] {
  let dir = $root | path join $'installer-($shell)'
  let fixture = $dir | path join fixture
  let stubs = $dir | path join stubs
  let cache = $dir | path join 'cache with spaces'
  let ready = $dir | path join ready
  mkdir $fixture $stubs $ready
  executable ($fixture | path join bendoom) "#!/bin/sh\nprintf '%s\\n' \"$@\"\n"
  let system = match [(^uname -s | str trim) (^uname -m | str trim)] {
    [Linux x86_64] => 'x86_64-linux'
    [Linux aarch64] => 'aarch64-linux'
    [Darwin arm64] => 'aarch64-darwin'
    _ => { error make {msg: 'Unsupported test platform'} }
  }
  let asset = $'bendoom-shareware-($system).tar.gz'
  ^tar -czf ($dir | path join $asset) -C $fixture .
  let digest = open --raw ($dir | path join $asset) | hash sha256
  $'($digest)  ($asset)(char newline)' | save ($dir | path join SHA256SUMS)
  let interpreter = $'#!($nu.current-exe) --no-config-file(char newline)'
  executable ($stubs | path join curl) ($interpreter + '
def --wrapped main [...args: string] {
  let url = $args | where {|a| $a | str starts-with "https://"} | first
  let output = $args | skip until {|a| $a == "-o"} | skip 1 | first
  cp ($env.FIXTURE | path join ($url | path basename)) $output
}
')
  executable ($stubs | path join tar) ($interpreter + '
def --wrapped main [...args: string] {
  ^$env.REAL_TAR ...$args
  "" | save ($env.READY | path join ($nu.pid | into string))
  for _ in 0..<100 {
    if (ls $env.READY | length) == 2 { return }
    sleep 50ms
  }
  error make {msg: "Concurrent extraction did not reach the barrier"}
}
')
  let fixture_env = {
    FIXTURE: $dir
    REAL_TAR: (which tar | first | get path)
    READY: $ready
    XDG_CACHE_HOME: $cache
    PATH: ([$stubs] | append $env.PATH)
  }
  let results = with-env $fixture_env {
    [1 2] | par-each --threads 2 {|_| ^$shell tools/play.sh 'argument with spaces' | complete }
  }
  for result in $results {
    assert equal $result.exit_code 0 $result.stderr
    assert equal ($result.stdout | str trim) 'argument with spaces'
  }
  let dest = $cache | path join bendoom $digest
  assert equal (glob --no-dir ($dest | path join '**/bendoom') | length) 1 'Concurrent installs nested a second bundle'
  assert equal (ls --all ($cache | path join bendoom) | where type == dir | length) 1 'Unused extracted bundles remain'
  let warm = with-env $fixture_env { ^$shell tools/play.sh cached | complete }
  assert equal $warm.exit_code 0 $warm.stderr
  assert equal ($warm.stdout | str trim) cached
  assert equal (ls $ready | length) 2 'Cached launch extracted the archive again'
  let wrong_digest = '0' | fill --width 64 --character '0'
  $'($wrong_digest)  ($asset)(char newline)' | save --force ($dir | path join SHA256SUMS)
  let rejected = with-env $fixture_env { ^$shell tools/play.sh | complete }
  assert ($rejected.exit_code != 0) 'A checksum mismatch must fail'
  assert not ($cache | path join bendoom $wrong_digest | path exists)
  assert equal (ls $ready | length) 2 'A corrupt archive reached extraction'
  print $'PASS ($shell): concurrent installs publish one bundle; cached launch reuses it'
}

def main [--only: string = all] {
  let root = mktemp --directory
  try {
    for shell in [bash dash] {
      if $only in [all recording] { recording $root $shell }
      if $only in [all installer] { installer $root $shell }
    }
  } finally {
    rm --recursive $root
  }
}
