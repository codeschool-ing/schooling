---
title: The perimeter, and what it can no longer do alone
version: 1
---

The **perimeter** is the boundary between a network an organisation controls and everything it does
not, and in practice it means the device at that boundary: the firewall between the company and the
internet. For a long time it was the whole of network security. Everything outside was hostile,
everything inside was trusted, and the firewall was the wall in between.

That model is called **castle and moat**, and it is worth understanding before taking it apart,
because it is still how most small networks are built, the shop's included.

A **firewall** is a device, or a program on one, that looks at each connection passing through it
and decides, from rules somebody wrote, whether to let it through. At this level a rule looks at the
connection's addresses and its **port**: the number that says which service on a machine it wants,
80 for a web page, 5432 for the PostgreSQL database, 22 for remote administration. `networks` lesson
3 explains ports, and `networks-security` lesson 1 explains how a firewall keeps track of
connections; here, "who may connect to which service on which machine" is enough.

The perimeter is still a useful layer. It is shared, so one set of rules protects every machine
behind it, and it blocks the noise of the whole internet before it reaches anything. What has
changed is that **it can no longer be the only line**, for three reasons that each stand alone:

| what changed | why the wall does not cover it |
|---|---|
| people work from home, from cafés, from their phones | the laptop leaves the castle every evening |
| services moved to the cloud | email, files and payments are outside the wall by design |
| attackers get inside without crossing it | a phishing email lands an attacker on a staff laptop that is already inside |

The third row is the important one. Once something on the inside is compromised, a network built on
"inside is trusted" offers it everything. The rest of this lesson builds the perimeter properly,
then shows why the inside needs walls too, and lesson 7 takes the idea to its end.

**One thing that is not a perimeter control: NAT.** Most home and small-office routers translate
private addresses to one public address, and a side effect is that unsolicited connections from the
internet do not reach inside machines. That side effect looks like a firewall and is not designed
as one. The course's lab has no NAT at all, so that its rules are the only thing deciding what
passes, and everything you see blocked below is blocked by a rule somebody wrote.
