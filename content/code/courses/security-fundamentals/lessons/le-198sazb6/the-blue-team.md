---
title: The blue team
version: 1
---

The colours come from military war games, where blue was the home side and red the opposing force,
and the convention moved into security with them. **The blue team defends.** In most organisations it
is not a special unit at all: it is everybody whose job is keeping systems secure and noticing when
they are not.

What the blue team does falls into three kinds of work, which line up with lesson 4's control
functions:

| work | what it means | at the shop |
|---|---|---|
| **prevent** | harden systems, apply patches, write firewall rules, manage access | lesson 5's zones, lesson 6's permissions, lesson 9's MFA |
| **detect** | collect logs, write rules that turn events into alerts, watch them | the portal's log, and somebody reading it |
| **respond** | contain an incident, remove the attacker, restore, learn | revoke a leaked password, restore from backup |

In a larger organisation the detect and respond work lives in a **security operations centre
(SOC)**: a team that watches alerts around the clock, sorts the real ones from the noise and starts
the response. At the shop, the blue team is ana, part of her week, with help from the owners when a
decision is needed. The work is the same; only its scale differs.

### The defender's disadvantage

Defenders are often told they have to be right every time while an attacker only has to be right
once. That is half true. It describes **prevention**: one missed patch can be enough to get in. It
does not describe **detection**, where the balance turns the other way: an attacker who is inside
has to stay invisible through every step, finding their way, reaching more machines, getting the
data out, and the defender only has to notice one of them. That is the reason lesson 4 called
detection a layer in its own right, and the reason so much blue team work is about logs.

The blue team's weakness is the one every builder has: **it tests what it thought of.** The firewall
of lesson 5 was tested from three zones because its author thought of three zones. An attacker is
under no obligation to arrive from one of them. The next two sections are about getting a view the
builders do not have.
