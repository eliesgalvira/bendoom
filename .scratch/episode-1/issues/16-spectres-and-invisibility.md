# 16: Spectres and partial invisibility

**Tier:** 3

**What to build:** things with vanilla's shadow flag draw with vanilla's fuzz column, offset table and running position. Partial invisibility gives the player vanilla's shadow duration, monster aim spread and fuzzed weapon blink.

**Blocked by:** 03

**Status:** ready-for-agent

- [x] Spectre full frame matches Chocolate after the same commands from map start.
- [x] Actual invisibility pickup, blink and expiry match full frames; former-human shots and baron missiles use source-confirmed shadow spread and match external outcomes.
- [x] Existing Freedoom render hashes and coverage assertions pass unchanged on native and JavaScript.

Full-frame comparisons cover E1M7 spectre12; E1M6 pickup12/1972/1973/1974/1982/2100/2101; former150 and baron100/150. Correcting projectile definitions from accidental MF_SHADOW to vanilla MF_DROPOFF restores the original long-fight1453 hash and coverage.

A controlled hazard-only fixture retains a visible non-aggressive spectre and matches all64000 pixels at20/650/652/670. Chocolate phase38 survives actual death/rebirth, then advances38->33 on rebirth652. Normal-exit completion51, first tally52 and loaded map68 also match full frames; phase16 survives the map load. The shared renderer draws the retained level while the new tally has bcnt0, matching Chocolate's final completion-command world draw without changing simulation, songs or export counts.

Remaining acceptance: actual Film fuzzy RGB under its declared command1..N draw schedule, product widths, affected checks after the final render seam, latest integration merge and review. Film keeps7006/8827560 and1680/2116800 contracts; reuse21's unchanged long audio/count evidence. Root owns the merged short finale export. No hashes have been repinned. The inherited lethal-melee death-camera divergence is preserved for22 and is not this ticket's lifecycle acceptance.
