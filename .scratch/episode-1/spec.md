# Knee-Deep in the Dead

**Status:** ready-for-agent

## Problem Statement

Bendoom plays one level. The shareware WAD it ships holds a whole episode, E1M1 to E1M9, and every map already loads and renders, but no map other than E1M1 can be finished. The exit restarts E1M1 with a fresh player. Doors other than a few kinds, most lifts and floors, stairs, teleporters, light and damage specials, the secret exit, the spectre, the baron, the chaingun, the rocket launcher and the powerups do nothing or are dropped silently. Music and sound effects are rendered at package build time for E1M1 only, so every other map would play the wrong song. The demon's attack sound is missing from the sound table, so it is silent today.

## Solution

The player starts at E1M1, or at any E1 map chosen at launch, and plays the shareware episode to its end as in vanilla Doom. Each exit leads through the intermission to the next map with the player's inventory carried over. The secret exit of E1M3 leads to E1M9 and back to E1M4. Killing the barons on E1M8 opens the way to the end, and the episode's closing text and end picture follow. Every map plays its own song, synthesized from the opened WAD while the game runs, and every sound effect comes from the opened WAD.

The work is judged by vanilla. The three demos inside DOOM1.WAD replay in Bendoom without drifting from Chocolate Doom, and frames and audio match Chocolate Doom exactly where the existing tools compare them.

The work lands in tiers. Each tier is a coherent build to play, and the overnight orchestrator ships the furthest tier it can finish by the deadline (see `docs/agents/orchestrator.md`).

- **Tier 1, the episode runs.** Launch at any E1 map; exits and the secret exit chain the maps with inventory carried; the intermission is right for all nine maps; every thing type in the shareware maps spawns and draws; music and sound effects come from the opened WAD, with each map's song.
- **Tier 2, the maps play.** Every line and sector special the shareware maps use works as in vanilla, so E1M1 to E1M7 and E1M9 can be finished.
- **Tier 3, the episode ends.** The spectre, the baron and E1M8's ending, the chaingun and the rocket launcher, the powerups, the episode's closing text, and the three WAD demos replaying in sync to their last tic.

## User Stories

### Playing the episode

1. As a player, I want to start a new game at E1M1, so that I play the episode from its beginning.
2. As a player, I want to start at any map from E1M1 to E1M9 with a launch option in the form Chocolate Doom takes (`-warp 1 5`), so that I can go straight to a map I want to play.
3. As a player, I want the exit switch or exit line of a map to end the level, so that I move on as in vanilla.
4. As a player, I want the intermission after each map to show that map's name, kills, items, secrets, time and par time, so that I see how I did.
5. As a player, I want the intermission's map screen to mark the maps I finished and point to the next one, so that I know where I am in the episode.
6. As a player, I want the next map to load after the intermission, so that the episode continues without restarting the game.
7. As a player, I want to keep my health, armour, weapons, ammo and backpack into the next map, and lose my keys and powerups, as vanilla's level change does, so that the episode plays like Doom.
8. As a player, I want E1M3's secret exit to take me to E1M9, so that I can find the secret level.
9. As a player, I want E1M9's exit to take me to E1M4, so that the episode continues where vanilla continues it.
10. As a player, I want the intermission after a secret exit to show E1M9 as the next map, so that I know I found it.
11. As a player, I want dying to restart the current map from a pistol start, so that a death does not send me back to E1M1.
12. As a player, I want each map's song to play while I am on it, the intermission's song during the tally, and the victory song during the closing text, so that the episode sounds like Doom.
13. As a player, I want every sound effect the shareware maps can make to play, including the demon's attack, so that nothing is silent that vanilla plays.

### Things in the maps

14. As a player, I want the red and yellow keycards to appear where the map puts them and to be picked up, so that I can open the doors they lock.
15. As a player, I want every decoration in the shareware maps to stand where the map puts it, with the same blocking and lighting as vanilla, so that the rooms look right.
16. As a player, I want every pickup in the shareware maps to appear and work, so that I find the items vanilla has.
17. As a player, I want things dropped by skill flags or multiplayer flags to be left out exactly as vanilla leaves them out, so that the random numbers stay in step with vanilla.
18. As a player, I want the status bar to show every key I hold, so that I know which doors I can open.

### Doors, lifts, floors and stairs

19. As a player, I want every door kind the shareware maps use (normal, stay-open, close-only, one-shot, repeatable, switch-opened, gun-opened, fast) to open, wait and close with vanilla's speeds and sounds, so that the maps open as designed.
20. As a player, I want red- and yellow-locked doors to refuse me without the key, with vanilla's message and sound, so that I know what I need.
21. As a player, I want doors that close and reopen after a wait to keep vanilla's timing, so that timed doors work.
22. As a player, I want every lift kind the shareware maps use to lower, wait and rise as vanilla's, so that I can reach other floors.
23. As a player, I want every floor kind the shareware maps use to raise or lower to vanilla's target, including those that change the floor's texture and special, so that the maps change as designed.
24. As a player, I want the donut special to work as vanilla's, so that the maps that use it play right.
25. As a player, I want stairs to build step by step as vanilla's, so that I can climb to the areas they reach.
26. As a player, I want switches to change their texture when pressed, play their sound and return if repeatable, so that I see what I pressed.
27. As a player, I want the lines that react to gunfire to react when I shoot them, so that shooting a switch opens what it opens.
28. As a player, I want monsters to open the doors and use the lines that vanilla lets them use, so that monsters follow me as in vanilla.

### Teleporters, lights and damage

29. As a player, I want to be teleported when I cross a teleport line, arrive at its destination facing its angle, see the fog and hear the sound, and stand still for vanilla's delay, so that teleporters work.
30. As a player, I want a teleport to kill whatever stands on the destination, as vanilla's does, so that telefrags happen.
31. As a player, I want monsters to use teleporters as vanilla lets them, so that the maps that rely on it play right.
32. As a player, I want every light special in the shareware maps (blinking, flickering, glowing, strobing, and lines that turn lights on or off) to look as in vanilla, so that the rooms flicker and glow as designed.
33. As a player, I want every damaging floor in the shareware maps to hurt me at vanilla's rate, so that hazards are hazards.
34. As a player, I want secret sectors to count toward the secrets total, so that the intermission's secret count is right.

### Monsters

35. As a player, I want spectres to appear as the shimmering fuzz vanilla draws, and to fight like demons, so that they are as hard to see as in vanilla.
36. As a player, I want barons to throw their green fireballs and claw at close range as vanilla's, so that they fight right.
37. As a player, I want every monster missile, not just the imp's, to fly, hit and explode as vanilla's, so that all monster attacks work.
38. As a player, I want killing both barons on E1M8 to lower the floor tagged for it, so that I can reach the end of the map.
39. As a player, I want E1M8's final room to end the level as vanilla's does, so that the episode can end.

### Weapons and powerups

40. As a player, I want the chaingun to fire as vanilla's, with its flash and its two-bullet rhythm, so that it is worth picking up.
41. As a player, I want the rocket launcher to fire rockets that explode and hurt everything in their blast, me included, so that it is the weapon vanilla gave me.
42. As a player, I want keys 4 and 5 to select the chaingun and rocket launcher if I own them, and a new weapon to be raised on pickup as vanilla does, so that weapon choice works.
43. As a player, I want partial invisibility to make monsters miss more and draw my weapon fuzzed, for vanilla's duration, so that the powerup does what it does in Doom.
44. As a player, I want the radiation suit to protect me from damaging floors as vanilla's does, with the green screen tint while it lasts, so that I can cross the nukage.
45. As a player, I want light amplification to light every room fully while it lasts, flickering before it runs out, so that I can see in the dark.
46. As a player, I want the computer map to be picked up with its message, so that it counts as an item even before the automap exists.

### The end of the episode

47. As a player, I want the closing text of episode one to type out over vanilla's background when E1M8 ends, so that I read the story's end.
48. As a player, I want the shareware's end picture to follow the text and stay until I quit, so that the episode ends as vanilla ends it.

### Recording and films

49. As a player, I want a recording to start at the map I launched and to continue across map changes until I quit, as vanilla's `-record` does, so that I can record a run of the whole episode.
50. As a player, I want the video exporter to play a recording through every map, intermission and the closing text, with each map's song, so that a run of the episode becomes one video.

### Browser

51. As a browser player, I want the web build to play the episode the same way, with its music and sounds, so that the site keeps working.

### Verification

52. As a maintainer, I want DOOM1.WAD's DEMO1 (E1M5), DEMO2 (E1M3) and DEMO3 (E1M7) to replay in Bendoom to their last tic with frames matching Chocolate Doom's, so that I know the sim matches vanilla on real play.
53. As a maintainer, I want `tools/oracle.nu` and its helpers to take a map and to replay a demo up to a chosen tic, so that I can compare any moment of any map against vanilla.
54. As a maintainer, I want every map's start view to match Chocolate Doom with zero differing pixels, so that each map's geometry and things are right.
55. As a maintainer, I want each special, monster and weapon this milestone adds to be compared against Chocolate Doom at a moment where it has acted, so that every new mechanic is checked against vanilla, not against itself.
56. As a maintainer, I want each map's song and the new sound effects compared with Chocolate Doom by `tools/listen.nu` with zero differing samples, so that runtime synthesis is exact.
57. As a maintainer, I want the game to hold 35 tics a second with no audio underruns on the largest shareware map, so that synthesizing music while playing costs nothing the player notices.
58. As a maintainer, I want the build-time music and sound renderers, their packaged files and `BENDOOM_MUSIC` and `BENDOOM_SOUNDS` gone once audio comes from the opened WAD, so that one path makes the audio.
59. As a maintainer, I want the laws to keep checking after every change, with any law a change must restate restated narrowly and its reason recorded, so that the proofs still mean something.
60. As a maintainer, I want `nix flake check` to pass on Freedoom after every tier, so that the check never needs the unfree WAD.

## Implementation Decisions

- **Prefactor first.** The line-special dispatch moves out of the sim's main module into a module of its own, before any special ticket starts, so that parallel tickets for doors, floors, teleporters and lights stop colliding in one 6,300-line file. Movers (doors, lifts, floors, stairs, donut) follow vanilla's thinkers in `p_doors.c`, `p_plats.c`, `p_floor.c` and `p_spec.c`.
- **Sector state belongs to the sim.** A sector's floor and ceiling heights, floor and ceiling flats, light level, special and tag become sim state, which the renderer reads. Today the special lives in the level geometry, which the sim restores every tic, so a special that changes a flat or a sector's special would be silently undone. The laws about the tic's rest and kept geometry are re-proved over the new state.
- **Exits have kinds.** The level's end is a kind (none, normal, secret), not a flag. The tally leads to the next map by vanilla's `G_DoCompleted` and `G_WorldDone` rules for episode 1: E1M3's secret exit to E1M9, E1M9 to E1M4, E1M8 straight to the finale, with no tally (`G_DoCompleted`'s `ga_victory` for map 8). A level change carries the player as vanilla's `G_PlayerFinishLevel` does. The path that restarts E1M1 after the tally is deleted.
- **Map choice.** The game takes the starting episode and map at launch as Chocolate Doom's `-warp` does, and from a demo's header when replaying one. Skill stays Hurt Me Plenty, or the demo header's skill when replaying, applied to spawn flags as vanilla applies it. Menus and skill selection are out of scope.
- **Intermission for the episode.** Par times, the "you are here" spots, map names and the next-map logic come from vanilla's tables for episode 1, replacing the fixed E1M1 values. The intermission plays D_INTER.
- **Things.** Every thing type that appears in DOOM1.WAD's maps gets vanilla's `mobjinfo` row and states, enough to spawn and draw with vanilla's random draws, before the mechanics behind them. Unknown types stay dropped, as now, for Freedoom maps outside this scope.
- **Missiles are general.** Missile spawning takes the missile type instead of assuming the imp's fireball. The baron's ball and the rocket use it. Rocket splash reuses the radius damage the barrels already use.
- **Spectre and fuzz.** Things with vanilla's shadow flag draw with vanilla's fuzz column, its offset table and its running position, so that frames match the oracle. Partial invisibility gives the player the shadow flag, with vanilla's aim spread for monsters and a fuzzed weapon sprite.
- **Fixed colormaps and palettes.** Light amplification uses vanilla's fixed colormap rule, including its blink before it runs out. The radiation suit's green palette follows vanilla's rule. Both are rendering paths the oracle checks.
- **Boss death.** On E1M8, vanilla's `A_BossDeath` lowers the floor tagged 666 once every baron is dead. Sector special 11 hurts the player and ends the level when health falls low enough, as vanilla's does.
- **Teleporters and the wall law.** Teleport behaviour follows vanilla's `EV_Teleport` and `P_TeleportMove` exactly, including the telefrag. Vanilla does not check the destination against walls, so the law that positions only change through checked moves cannot hold as stated. The law is restated with one narrow exception: a tic that does not teleport keeps the player in free space, and a teleport puts the player at a teleport destination thing. The ticket must record the exact LAWS.bend changes for maintainer review.
- **Audio from the opened WAD.** Music is synthesized while the game runs, buffer by buffer, from the current song lump and the WAD's GENMIDI, through the existing OPL emulation and its Chocolate Doom timing. Sound effects are expanded from the opened WAD's sound lumps when the game starts. The sound table grows to every sound the shareware content can play. The build-time music and sound nodes, their packaged files, and `BENDOOM_MUSIC` and `BENDOOM_SOUNDS` are deleted once the runtime path matches. The film exporter and the web build use the same path.
- **Demos span maps.** A recording's header names the map it starts on and keeps recording through level changes. Replaying a demo follows it through its maps, as vanilla's playback does.
- **Tools take a map.** The oracle, the demo writer, the WAD reader, the frame dumper and the walk tool take an episode and map instead of assuming E1M1, and the oracle can replay a WAD demo lump or a `.lmp` file up to a chosen tic before comparing.
- **Width.** The native backend caps a record at 255 live words (see `docs/bend.md`), and the game's Bend-to-C compile already peaks at 12.2 GB. New state goes into new records, not into the widest ones, and a ticket that grows a record reports the margin left.

## Testing Decisions

- **One seam: the demo.** Every gameplay check is a demo, either a WAD demo lump, a recorded `.lmp`, or a command script the tools turn into one, played by both Bendoom and Chocolate Doom on the same WAD. `tools/oracle.nu` compares the frame at a chosen tic with zero differing pixels as the bar. `tools/listen.nu` compares audio with zero differing samples. Below that seam, the `#|` tests in `tests/` pin sim results on Freedoom on both backends, and only after the oracle agrees.
- **Good tests check what the player sees and hears, not how the code gets there.** A door test is a frame with the door open at rest, compared with vanilla, not an assertion about a mover's fields.
- **Expected values come from outside the code.** They come from Chocolate Doom, its source or the WAD, as `AGENTS.md` requires. A value with no oracle is a regression pin, and its ticket says so.
- **Demo sync is the episode's acceptance.** DEMO1 (E1M5, 5,026 tics), DEMO2 (E1M3, 3,836 tics) and DEMO3 (E1M7, 2,134 tics), all Hurt Me Plenty, are compared at several tics through each demo and at its last tic. A differing frame means a desync. Before reporting one, rule out the oracle (see `docs/agents/orchestrator.md`).
- **Freedoom keeps the flake check.** The flake check and the dev shell stay on Freedoom, because the check must not need the unfree WAD. Shareware results are ticket evidence from the oracle. Freedoom's DEMO1 (E1M6, Hurt Me Plenty) becomes a pinned test if its things are all implemented by then; it is not required.
- **Per-map start views.** Every map E1M1 to E1M9 compares at its player start with zero differing pixels. Today 13 of 15 checked starts already do; E1M2's red key and E1M6's dropped types are the known differences.
- **Each mechanic is checked where it acts.** Each special, monster and weapon gets a scripted demo on a shareware map that uses it, compared at a rest moment after it acts: a door fully open, a lift at the bottom, the last stair built, the player just teleported, a baron's ball mid-flight, a rocket's blast.
- **Transitions.** A scripted run takes an exit, compares the tally with `--screen tally`, then compares the next map's first frame, with the carried inventory visible on the status bar.
- **The render test's rest positions stay at zero.** New rest positions on Freedoom maps are added where the oracle agrees.
- **Laws.** LAWS.bend and PROOF.bend keep checking. The teleport exception and the sector-state change are the expected law edits.
- **Performance.** The largest shareware maps (E1M6, E1M9) are measured for frame time and tic time with music synthesizing, and audio underruns are counted with the window bench's existing counter.
- **Prior art:**
  - `tests/fight.bend`, the 1,453-tic Freedoom fight pinned by state and final frame
  - `tests/route.bend` and `tests/tally.bend`
  - `tools/oracle.nu` with `--screen tally`
  - `tools/listen.nu`
  - `tests/sounds.bend` and `tests/mixer.bend`
  - the frame hashes in `tests/render.bend`

## Out of Scope

- Cheats. They are planned for the next night, where `idclip` needs a decision on the wall law.
- Menus, skill selection, episode selection, options, pause and the quit prompt.
- Save and load.
- The automap, and with it `iddt` and the computer map's reveal.
- The title screen and attract loop. The WAD demos are used for verification only.
- The screen wipe between scenes.
- Nightmare skill, fast monsters and respawning.
- Freedoom's content beyond what shareware E1 needs: the lost soul, cacodemon, cyberdemon and spider mastermind, the plasma rifle and BFG, crushers, invulnerability, and the line specials only episodes 2 to 4 use. Freedoom maps keep loading, and some cannot be finished yet.
- The registered and Ultimate Doom WADs, and multiplayer.

## Further Notes

- **Pending maintainer review:** the teleport exception to the wall law; it can be reversed.
- **Measured headroom.** On 2026-10-01 every shareware map loaded in 0.11 to 0.23 s. Each rendered its start view in 3.4 to 7.2 ms and ran a tic in 0.33 to 3.4 ms, against 28.6 ms per tic, at about 130 MB. Freedoom's largest maps reach 12 to 15 ms per tic, which matters only beyond this scope.
- **Absorbed ticket.** The open ticket "Render audio from the opened WAD" is folded into this spec and deleted.
- **The milestone after this one:** cheats, then menus, save/load, the automap and the title loop, then Freedoom's episodes 2 to 4.
