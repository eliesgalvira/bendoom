# 11: Stairs

**Tier:** 2

**What to build:** the stair specials 7 (E1M8) and 8 (E1M3) build step by step as vanilla's `EV_BuildStairs`, following matching floor textures through the neighbouring sectors with vanilla's speed and step height.

**Blocked by:** 10 (both extend the floor mover)

**Status:** ready-for-agent

- [ ] On E1M3 and E1M8, a scripted demo compares with Chocolate Doom mid-build and after the last step: zero differing pixels.
- [ ] Climbing the finished stairs reaches what they lead to, matching vanilla's frame at the top.
