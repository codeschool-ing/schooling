---
title: The power budget
version: 1
---

A "24-port PoE switch" does not promise 24 ports of full power. **A PoE switch has one power
budget, a total in watts shared by every port**, and it is printed on the datasheet beside the port
count, usually smaller than the port count suggests. Running out of it is not a crash: the switch
refuses power to a port, and a phone that worked yesterday stays dark today with its cable plugged in.

The numbers below are a worked example, not a lab capture: a hypothetical 24-port switch with a
PoE budget of **370 W**, and the per-port figures from the previous section's table.

## Doing the sums

Start with the ceiling. If all 24 ports powered a Type 1 device at its maximum, they would need
24 × 15.4 W = **369.6 W**, just under the budget. So this switch can give full 802.3af power to
every port at once, and not one watt more. Twenty-four Type 2 devices at 30 W would need 720 W, nearly
twice what it has.

Now a real floor plan. The switch feeds:

| devices | each reserves | count | total |
| --- | --- | --- | --- |
| desk phones, class 2 | 7 W | 10 | 70 W |
| access points, Type 2 (class 4) | 30 W | 6 | 180 W |
| outdoor cameras, Type 3 | 60 W | 2 | 120 W |
| **all of them** | | **18** | **370 W** |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two bars on a scale from 0 to 400 watts, against a budget line at 370 W. The first bar, the plan, is 10 desk phones at 7 W each, 70 W; 6 access points at 30 W each, 180 W; and 2 cameras at 60 W each, 120 W; together exactly 370 W. The second bar adds a seventh access point, 30 W more, which takes the total to 400 W and crosses the budget line by 30 W.\"><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the plan: 18 devices, 370 W</text><rect x=\"30.0\" y=\"46\" width=\"105.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"82.5\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10 phones, 70 W</text><rect x=\"135.0\" y=\"46\" width=\"270.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6 access points, 180 W</text><rect x=\"405.0\" y=\"46\" width=\"180.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 cameras, 120 W</text><text x=\"30\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">with a seventh access point: 400 W</text><rect x=\"30.0\" y=\"118\" width=\"105.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"82.5\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10 phones, 70 W</text><rect x=\"135.0\" y=\"118\" width=\"270.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6 access points, 180 W</text><rect x=\"405.0\" y=\"118\" width=\"180.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 cameras, 120 W</text><rect x=\"585.0\" y=\"118\" width=\"45.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"607.5\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+30 W</text><path d=\"M585.0 22 L585.0 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"579.0\" y=\"14\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">budget 370 W</text><path d=\"M30 176 L630.0 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M30.0 176 L30.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"30.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 W</text><path d=\"M180.0 176 L180.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 W</text><path d=\"M330.0 176 L330.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200 W</text><path d=\"M480.0 176 L480.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"480.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 W</text><path d=\"M630.0 176 L630.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400 W</text></svg>", "caption": "A worked example, not a capture. The plan uses the hypothetical switch's whole 370 W budget with six ports still free, so one more 30 W device is a device the switch refuses to power."}
```

Eighteen devices use the whole 370 W, with six ports still free. **Ports and power run out
separately**, and here power runs out first. A seventh access point would bring the total to 400 W,
30 W over, and something will not get power.

The phones show why classes matter. Had they announced class 0, or class 3, each would reserve 15.4 W
instead of 7 W: 154 W for the ten instead of 70 W, and the plan above would be 84 W over
budget.

## What the switch does when the budget is short

Two decisions are made in the switch's configuration, and both are worth making on purpose.

**How power is counted.** A switch can reserve what each port's class allows, as the table did, or
count what each device is actually drawing at the moment. Counting the actual draw fits more devices
on the same budget, since a phone reserving 7 W may draw less. The risk is the day the draw rises all
at once: cameras switching on their heaters on a cold night ask for what they were always entitled to,
and the budget that looked comfortable at noon is short at midnight.

**Which ports lose.** Ports can be given a priority, and when the budget is exceeded the switch
refuses or removes power on the lowest-priority ports first. **Decide in advance what goes dark.**
Phones that carry emergency calls, and the access points in the areas that need coverage, belong at
the top; a decorative display at the bottom. Without priorities, the outcome is whatever the
switch's default rule happens to be, which is not a plan.

Two practical checks finish the job. Add the planned devices up, with their classes, before buying
the switch, and keep some of the budget spare for the device somebody adds next year. And remember
the switch's own supply: the PoE budget is on top of what the switch needs to run itself, and on some
models a second power supply is what raises the budget.
