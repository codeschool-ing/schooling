---
title: Power over Ethernet, the budget nobody adds up
version: 1
---

An enterprise AP takes its power from the switch port, over the same cable as its data: Power over
Ethernet, from lesson 21 of `networks-addressing`. The standards set what a switch port supplies and what
reaches the device after the cable's loss:

| standard | at the switch port | at the device |
|---|---|---|
| 802.3af (PoE) | 15.4 W | 12.95 W |
| 802.3at (PoE+) | 30 W | 25.5 W |
| 802.3bt type 3 | 60 W | 51 W |
| 802.3bt type 4 | 90 W | 71.3 W |

Two numbers decide whether a design works, and neither is the one on the front of the box.

**What the AP needs.** Many current APs, with several radios and several spatial streams each, need
802.3at or 802.3bt to run everything. On less power, a good number of them do not refuse to start: **they
boot and run with a radio or some streams switched off**, and say so in a log line. The network works,
with less capacity than was designed, and nothing on the surface says why. That is the kind of silent
failure the AP's power status on the switch exists to catch.

**What the switch can supply in total.** A 24-port switch with PoE on every port does not have 24 × 30 W to
give. Its **PoE budget** is a separate figure on its data sheet, often much smaller than ports times the
maximum. How it is spent depends on the switch. Some reserve power by class, the full 30 W for any 802.3at
device whether it draws it or not; others allocate what the device asks for over LLDP, or what it draws.
Planning with the class reservation is the safe assumption.

A worked case: one switch, sixteen APs that need 802.3at, and six cameras on 802.3af:

```schooling-example
{"language": "python", "file": "poe.py", "parts": [{"code": "budget_w = 370                  # the switch's PoE budget, from its data sheet\nreserve_w = {\"802.3af\": 15.4, \"802.3at\": 30.0, \"802.3bt type 3\": 60.0}", "note": "The switch's total, and what a port reserves per standard when the switch allocates by class: the power at the switch port, before the cable's loss. 370 W is an example figure for a 24-port switch, not a standard."}, {"code": "aps, cameras = 16, 6\nneed = aps * reserve_w[\"802.3at\"] + cameras * reserve_w[\"802.3af\"]\nprint(f\"reserved: {aps} x 30.0 + {cameras} x 15.4 = {need:.1f} W of {budget_w} W\")\nprint(f\"short by {need - budget_w:.1f} W\")", "note": "Sixteen access points that need 802.3at, and six cameras on 802.3af, all on one switch."}, {"code": "fits = int((budget_w - cameras * reserve_w[\"802.3af\"]) // reserve_w[\"802.3at\"])\nprint(f\"802.3at access points that fit beside the cameras: {fits}\")", "note": "What does fit, once the cameras have their share."}], "output": "reserved: 16 x 30.0 + 6 x 15.4 = 572.4 W of 370 W\nshort by 202.4 W\n802.3at access points that fit beside the cameras: 9"}
```

**572.4 W reserved against a 370 W budget.** The switch powers ports in its own order of priority until the budget is spent, and refuses the rest. With the cameras served, **nine APs
fit**. The fixes are a switch with a larger budget, a second switch, or APs spread over the switches that
the design already has.

## Spread them anyway

Even when the budget fits, putting every AP of one floor on one switch makes that switch a single point of
failure for the floor's whole wireless network. **Alternate neighbouring APs between two switches**, and a
switch that fails leaves every other cell working and the coverage patchy rather than gone, which is the
redundancy thinking of lesson 14 applied to a ceiling.
