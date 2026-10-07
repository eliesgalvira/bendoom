# 09: Every door the shareware maps use, with keyed doors and gun-triggered lines

**Tier:** 2

**What to build:** the door specials of DOOM1.WAD's maps work as vanilla's `p_doors.c`: 16 (E1M6), 27 yellow-locked (E1M3 to E1M7), 28 red-locked (E1M2, E1M6, E1M7), 31 (E1M2 to E1M4, E1M7 to E1M9), 32 blue (E1M9), 33 red (E1M9), 34 yellow (E1M7, E1M9), 46 opened by gunfire (E1M2), 63 (E1M3, E1M7), 76 (E1M6), 86 (E1M4), 90 (E1M3 to E1M5, E1M7, E1M9) and 103 (E1M2, E1M3, E1M5, E1M6, E1M9); check the list against the WAD. Locked doors refuse the player without the key with vanilla's message and sound. Bullets that hit a gun-triggered line activate it, as vanilla's `P_ShootSpecialLine`. Monster attempted uses follow vanilla, including its successful attempted-use reporting when a manual locked door rejects the actor. Switch textures change on every switch these use.

**Blocked by:** 01, 03 (keycards)

**Status:** ready-for-human

- [x] For each door special, a scripted demo on a map that has it compares with Chocolate Doom at the door fully open and, where it closes, fully closed again: zero differing pixels.
- [x] A locked door without the key matches vanilla's frame with the message showing; with the key, it opens.
- [x] Shooting E1M2's gun-triggered line opens its door, matching vanilla.
- [x] A monster opening a door it may open is shown matching vanilla, or the ticket names the vanilla rule it checked and why no demo shows it.

**Pending focused reviews:** corrected active door, key, gunfire and switch views compare with zero unmasked pixels. Enabled refusal messages compare with zero pixels, and six isolated door/refusal/switch audio cases compare with zero differing samples after audible-lead alignment. The branch-selection correction passes affected native and JavaScript tests, proof and representative door/button frames. Both focused reviews must clear before this ticket is removed.

**Monster rule checked:** Chocolate Doom 3.1.1 `src/doom/p_switch.c:288–305` allows a nonplayer's attempted use only for nonsecret specials 1, 32, 33 and 34. `p_doors.c:344–389` immediately rejects a nonplayer for locked 32–34; `p_switch.c:309–329,639` still returns true for those accepted attempts. `p_enemy.c:300–321` uses that result to report the attempted use. Special 1 can open or reverse a closing door, but a monster does not close an already moving door, as `p_doors.c:399–431` specifies. The Bend dispatch and door code have been checked against these rules. The retained E1M1 candidate with a zombie behind line 151 compares at zero but shows a closed panel at tic 116, so it demonstrates a static frame, not monster activation. No retained demo demonstrates an opening; the checked-rule alternative above satisfies the criterion without claiming one.

**Invalid route retained:** the old E1M3 line54 start lies in sector 51 with floor and ceiling both 64, below the player's required 56 clearance. Its 55-pixel failure remains in ignored research; its cause has not been independently diagnosed. It is excluded from acceptance. Two valid stock kind 2 routes replace it and compare at zero with visible openings.
