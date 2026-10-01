# 14: Recordings and films span the maps

**Tier:** 2

**What to build:** a recording's header names the map it starts on, and `RECORD` keeps recording through level changes until the player quits, as vanilla's `-record` does. Replaying a demo follows it through its maps, with the tally between them. The film exporter turns a multi-map recording into one video, with each map's song and the intermissions.

**Blocked by:** 05, 06

**Status:** ready-for-agent

- [ ] A recording started with `-warp 1 2` names E1M2 in its header, and Chocolate Doom plays it from E1M2.
- [ ] A recording that crosses the E1M1 exit into E1M2 replays in Chocolate Doom into E1M2, and its last frame matches Bendoom's replay of it.
- [ ] The film of that recording shows both maps and the tally, with each map's song.
- [ ] The README's recording section describes the new behaviour.
