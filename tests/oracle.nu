use std/assert
source ../tools/wad.nu

def executable [file: path, body: string] {
  $'#!(which sh | first | get path)(char newline)($body)(char newline)' | save --force $file
  ^chmod +x $file
}

def fixture [root: path] {
  let wad = open --raw $env.BENDOOM_IWAD
  mut pixels = 0..<64000 | each { '00' }
  for p in (patch-pixels $wad M_PAUSE 126 4) { $pixels = $pixels | update $p.at $p.colour }
  let raw = $pixels | str join | decode hex
  $raw | save ($root | path join frame.raw)
  ['00' ($pixels | chunks 320 | each { str join })] | flatten | str join (char newline) | save ($root | path join frame.hex)
  let header = [0x[0a050108000000003f01c700] (0..<53 | each { 0x[00] } | bytes collect) 0x[014001] (0..<60 | each { 0x[00] } | bytes collect)] | bytes collect
  let encoded = $pixels | each {|p| if $p =~ '^[c-f]' { $'c1($p)' } else { $p } } | str join | decode hex
  let pal = $wad | lump-pos PLAYPAL
  [$header $encoded 0x[0c] ($wad | bytes at $pal..($pal + 767))] | bytes collect | save ($root | path join frame.pcx)
}

def main [--only: string = all] {
  let owner = 'research/oracle-tests' | path expand
  mkdir $owner
  let root = mktemp --directory --tmpdir-path $owner test.XXXXXX
  let oracle = 'tools/oracle.nu' | path expand
  try {
    let stubs = $root | path join bin
    mkdir $stubs
    let frame = $stubs | path join frame
    let capture = $stubs | path join capture
    let timeout = which timeout | first | get path
    for command in [cat sleep cp kill] { ln --symbolic (which --all $command | where type == external | first | get path) ($stubs | path join $command) }
    fixture $root
    let cases = [xvfb-missing xvfb-failure chocolate-missing chocolate-failure capture-missing capture-failure capture-timeout frame-missing frame-failure frame-timeout frame-short frame-malformed capture-short pcx-short pcx-pixels-short pcx-malformed empty-faces capture-success capture-unmasked screenshot-success keep-success keep-failure negative-count negative-tic]
    for scenario in ($cases | where {|s| $only == all or $only == $s }) {
      executable ($stubs | path join Xvfb) 'echo $$ >> "$FIXTURE/children"; printf "42\n"; exec sleep 60'
      executable ($stubs | path join chocolate-doom) 'echo $$ >> "$FIXTURE/children"; cp "$FIXTURE/frame.pcx" DOOM00.pcx; exec sleep 60'
      executable ($stubs | path join xdotool) 'echo 1'
      executable $frame 'cat "$FIXTURE/frame.hex"'
      executable $capture 'cp "$FIXTURE/frame.raw" "$BENDOOM_CAPTURE_FRAME"; echo "CAPTURE tic $BENDOOM_CAPTURE_TIC gamestate 0 wi 0" >&2'
      mut flags = [--capture $capture]
      mut expected = ''
      mut position = ['-416' '256' '0' '20,0,0,0,0']
      mut search_path = [$stubs] | append $env.PATH
      match $scenario {
        negative-count => { $position = ['-416' '256' '0' '20,0,0,0,0 -1,0,0,0,0']; $expected = 'non-negative' }
        negative-tic => { $position = [demo DEMO1 '-1']; $expected = 'non-negative' }
        xvfb-missing => { rm ($stubs | path join Xvfb); $search_path = [$stubs]; $expected = 'Xvfb' }
        chocolate-missing => { rm ($stubs | path join chocolate-doom); $search_path = [$stubs]; $flags = []; $expected = 'Chocolate' }
        frame-missing => { rm $frame; $expected = 'frame' }
        capture-missing => { rm $capture; $expected = 'capture' }
        frame-timeout => { executable $frame 'echo $$ > "$FIXTURE/child.pid"; exec sleep 60'; $flags = $flags ++ [--timeout '500ms']; $expected = 'frame timed out' }
        capture-timeout => { executable $capture 'echo $$ > "$FIXTURE/child.pid"; exec sleep 60'; $flags = $flags ++ [--timeout '500ms']; $expected = 'capture timed out' }
        keep-failure => { executable $frame 'echo "fixture: kept diagnostic" >&2; exit 11'; $flags = $flags ++ [--keep]; $expected = 'fixture: kept diagnostic' }
        xvfb-failure => { executable ($stubs | path join Xvfb) 'echo "fixture: X server refused" >&2; exit 7'; $expected = 'fixture: X server refused' }
        chocolate-failure => { $flags = []; executable ($stubs | path join chocolate-doom) 'echo "fixture: Chocolate refused"; exit 8'; $expected = 'fixture: Chocolate refused' }
        capture-failure => { executable $capture 'echo "fixture: capture refused" >&2; exit 9'; $expected = 'fixture: capture refused' }
        frame-failure => { executable $frame 'echo "fixture: frame refused" >&2; exit 10'; $expected = 'fixture: frame refused' }
        frame-short => { executable $frame 'printf "00\n00\n"'; $expected = 'native frame' }
        frame-malformed => { executable $frame 'tr 0 z < "$FIXTURE/frame.hex"'; $expected = 'native frame' }
        capture-short => { executable $capture 'printf x > "$BENDOOM_CAPTURE_FRAME"; echo "CAPTURE tic $BENDOOM_CAPTURE_TIC gamestate 0 wi 0" >&2'; $expected = '320 by 200' }
        pcx-short => { $flags = []; executable ($stubs | path join chocolate-doom) 'printf x > DOOM00.pcx; exec sleep 60'; $expected = 'PCX' }
        pcx-malformed => { $flags = []; executable ($stubs | path join chocolate-doom) 'dd if=/dev/zero of=DOOM00.pcx bs=64897 count=1 2>/dev/null; exec sleep 60'; $expected = 'PCX' }
        pcx-pixels-short => {
          let pcx = open --raw ($root | path join frame.pcx) | into binary
          [($pcx | bytes at 0..<129) ($pcx | bytes at (($pcx | bytes length) - 769)..)] | bytes collect | save --force ($root | path join short.pcx)
          $flags = []
          executable ($stubs | path join chocolate-doom) 'echo $$ >> "$FIXTURE/children"; cp "$FIXTURE/short.pcx" DOOM00.pcx; exec sleep 60'
          $expected = 'complete 320 by 200'
        }
        keep-success => { $flags = $flags ++ [--keep] }
        capture-unmasked => { $flags = $flags ++ [--unmasked] }
        screenshot-success => { $flags = [] }
        capture-success => {}
        empty-faces => {
          let wad = open --raw $env.BENDOOM_IWAD
          let directory = $wad | bytes at 8..11 | into int --endian little
          mut changed = $wad
          for l in ($wad | lumps | enumerate | where {|l| $l.item.name | str starts-with STF }) {
            let at = $directory + $l.index * 16 + 8
            $changed = [($changed | bytes at 0..<$at) 0x[5858585858585858] ($changed | bytes at ($at + 8)..)] | bytes collect
          }
          $changed | save --force ($root | path join faceless.wad)
          $flags = $flags ++ [--wad ($root | path join faceless.wad)]
          $expected = 'face patches'
        }
      }
      let args = $flags
      let position_args = $position
      let search = $search_path
      let limit = if ($scenario | str starts-with pcx) or $scenario in [screenshot-success capture-success capture-unmasked keep-success] { '12s' } else { '6s' }
      let result = with-env {PATH: $search, FIXTURE: $root} {
        cd $root
        ^$timeout $limit $nu.current-exe --no-config-file $oracle ...$position_args --frame $frame ...$args | complete
      }
      assert ($result.exit_code != 124) $'($scenario): waited for a dead process'
      if $expected == '' {
        assert equal $result.exit_code 0 $result.stderr
        assert ($result.stdout =~ 'differing.*0') $result.stdout
        assert ($result.stdout =~ 'palette.*0') $result.stdout
        assert ($result.stdout =~ 'shot_plain.*true') $result.stdout
        if $scenario == capture-unmasked { assert ($result.stdout =~ 'masked.*0') $result.stdout }
      } else {
        assert ($result.exit_code != 0) $'($scenario): unexpectedly succeeded'
        assert ($result.stderr | str contains $expected) $result.stderr
      }
      let kept = glob ($root | path join research oracle '*')
      if $scenario in [keep-failure keep-success] {
        assert equal ($kept | length) 1
        if $scenario == keep-failure { assert (open --raw ($kept.0 | path join frame.err) | str contains 'fixture: kept diagnostic') } else { assert ($kept.0 | path join ours.hex | path exists) }
        rm --recursive $kept.0
      } else { assert equal ($kept | length) 0 'Failed oracle left scratch behind' }
      let pid = $root | path join child.pid
      if ($pid | path exists) {
        let alive = ^kill -0 (open --raw $pid | str trim) | complete
        assert ($alive.exit_code != 0) 'Timed-out child is still running'
        rm $pid
      }
      let children = $root | path join children
      if ($children | path exists) {
        for pid in (open --raw $children | lines) {
          assert ((^kill -0 $pid | complete | get exit_code) != 0) 'Oracle left a process running'
        }
        rm $children
      }
      print $'PASS ($scenario)'
    }
  } finally {
    for name in [children child.pid] {
      let file = $root | path join $name
      if ($file | path exists) { for pid in (open --raw $file | lines | into int) { kill --force --quiet $pid } }
    }
    rm --recursive $root
  }
}
