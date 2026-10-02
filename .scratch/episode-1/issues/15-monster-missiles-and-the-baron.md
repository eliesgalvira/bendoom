# 15: Every monster missile, and the baron

**Tier:** 3

**What to build:** spawning a missile takes the missile's type instead of assuming the imp's fireball, and the baron fights as vanilla's: `A_BruisAttack` claws at melee range and throws its green ball otherwise, with its pain, death and sounds. The baron's ball flies, hits and explodes as vanilla's. Ticket 03 already gave the baron its idle and run rows (261 to 270), its pain rows (271, 272) and its death rows (273 to 279, without `A_BossDeath`, ticket 19's), and its sight and death sounds; its melee and missile states are 0 in `Thing.fight.row`, which keeps its `A_Chase` from attacking (and from `P_CheckMissileRange`'s draw) until this ticket's attack rows.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] On E1M8, a scripted demo compares with Chocolate Doom at a baron's ball mid-flight and at its impact: zero differing pixels.
- [ ] The imp's fireball is unchanged: its existing tests and frame pins pass as before.
- [ ] A baron's death compares with vanilla's at rest.
