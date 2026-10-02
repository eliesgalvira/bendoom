# Bendoom

> [!WARNING]
> SLOP WARNING: There has been no adult supervision of the code.

Doom's first level, E1M1, written in [Bend 2](https://bend-lang.com).
Play through the level with monsters, weapons, doors, pickups, sound effects,
OPL music and the intermission screen. Record a demo and export it as a video.

Choose the original Doom shareware assets or [Freedoom](https://freedoom.github.io).
Both versions include their game data; you do not need to supply a WAD.

## Play

Available for Linux x86-64, Linux ARM64 and Apple Silicon macOS.
Linux requires X11 or Xwayland. CI checks all three platforms; macOS gameplay
and audio still need a hardware test.

### Without Nix

Run the shareware version:

```sh
curl -fsSL https://github.com/eliesgalvira/bendoom/releases/latest/download/play.sh | sh
```

Or choose Freedoom:

```sh
curl -fsSL https://github.com/eliesgalvira/bendoom/releases/latest/download/play.sh | sh -s -- --freedoom
```

The launcher downloads the release for your platform, verifies its SHA-256
checksum and starts the game. Run the same command next time; it reuses the
download in `~/.cache/bendoom`, or under `XDG_CACHE_HOME` if set.

For a manual download, extract your platform's archive from
[GitHub Releases](https://github.com/eliesgalvira/bendoom/releases/latest),
then run `./bendoom` inside the extracted directory. Neither Nix nor Nushell
is needed to play these releases.

### With Nix

The commands below use `--accept-flake-config` to accept this flake's cache
settings without prompting, so Nix can download prebuilt packages from
`bendoom.cachix.org`. This flag applies to the invocation; it does not change
your global Nix settings.

Run the shareware version:

```sh
nix run --accept-flake-config github:eliesgalvira/bendoom
```

Or choose Freedoom:

```sh
nix run --accept-flake-config github:eliesgalvira/bendoom#bendoom-freedoom
```

If your Nix installation does not enable flakes, add
`--extra-experimental-features 'nix-command flakes'` after `nix`.

## Controls

| Action | Keys |
| --- | --- |
| Walk forward / backward | Up / Down, or W / S |
| Turn left / right | Left / Right |
| Strafe left / right | A / D |
| Run | Hold Shift |
| Fire | Ctrl |
| Open doors / press switches | Space |
| Select fist / pistol / shotgun / chaingun | 1 / 2 / 3 / 4, if owned |
| Restart after dying | Space |
| Quit | Esc, or close the window |

## Record and export a video

Recording saves a Doom `.lmp` demo. Exporting replays that demo to produce
an MP4; these are two separate steps. The video exporter requires Nix.

### 1. Record your game

For shareware:

```sh
env RECORD=run.lmp nix run --accept-flake-config github:eliesgalvira/bendoom
```

Play, then **quit with Esc or close the window**. Recording also ends when
you finish the level. Ctrl+C aborts the recording; an existing demo is preserved.
Wait until the game exits and your terminal prompt returns
before exporting.

### 2. Export the saved demo

From the same directory:

```sh
nix run --accept-flake-config github:eliesgalvira/bendoom#film -- run.lmp run.mp4
```

The video is 1600 × 1200 at 35 frames per second, with music and sound effects.
A completed level includes the intermission count-up and a three-second hold
on the final scores. The exporter refuses to overwrite an existing video;
choose another output filename to export again.

### Recording Freedoom

Use the matching game and exporter. First record:

```sh
env RECORD=freedoom.lmp nix run --accept-flake-config github:eliesgalvira/bendoom#bendoom-freedoom
```

After the game exits, export:

```sh
nix run --accept-flake-config github:eliesgalvira/bendoom#film-freedoom -- freedoom.lmp freedoom.mp4
```

You can also record from an extracted portable release with
`env RECORD=run.lmp ./bendoom`, then export through Nix using the matching
shareware or Freedoom exporter. The `.lmp` files can also be played by
Chocolate Doom with the matching WAD.

## Development

From a checkout, enter the development environment:

```sh
nix develop
```

To check the proofs and run the tests:

```sh
nix flake check -L
```

[LAWS.bend](LAWS.bend) states the simulation's invariants;
[PROOF.bend](PROOF.bend) proves them. Bend tests run on both the native and
JavaScript backends. The checks also test the launchers.

Vanilla Doom is the reference for gameplay and rendering.
[tools/oracle.nu](tools/oracle.nu) compares frames against Chocolate Doom on
a headless display. Its usage and prerequisites are documented in the script.
Read [docs/bend.md](docs/bend.md) before changing Bend code or proofs.

### Browser build

```sh
nix build .#web
```

`result/` contains the static website, its Vercel header configuration, the
page's art drawn from the WAD at build time (`tools/web-art.cjs`), and
`og.png`, the link preview that headless Chromium captures from the page.
The package is offered on Linux, where nixpkgs has Chromium.
Deploy that directory as a separate Vercel project. It needs HTTPS and the
included cross-origin isolation headers for its WebAssembly workers.
The browser build currently allocates 1 GiB and requires a desktop keyboard.

The native compiler is pinned by `bend-src`; the browser compiler is pinned
independently by `bend-web-src`. Browser runtime patches are in
`nix/web-audio.patch` and `nix/web-runtime.patch`. Both builds use the same
game source. On x86-64 Linux, `nix flake check` also checks browser gameplay
and audio. CI uploads the website as the `website` artifact.

## Project status

E1M1 is playable with combat, sound effects and music.
Open issues live under [.scratch/](.scratch/).
The next milestone is **Hellbent**: the game as a single λ-expression.

## License

The code is [GPL-2.0-or-later](LICENSE). Doom's shareware assets and Freedoom's
BSD-licensed assets remain under their respective licenses.

`src/tables.bend` and `src/opl_tables.bend` are generated from Chocolate Doom's
GPL-2.0-or-later source. `src/sfx_taps.bend` is generated by
`tools/gen_sfx_taps.nu` from SDL's resampler filter; SDL is under the zlib license.
