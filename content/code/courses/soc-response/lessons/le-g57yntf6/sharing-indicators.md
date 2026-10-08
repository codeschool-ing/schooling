---
title: Sharing indicators without harm
version: 1
---

Indicators leave the company when it shares what it learned (lesson 8), and they arrive from others. Four
habits keep that exchange from doing harm.

**Give every indicator a life.** An address used for guessing this week can be reassigned to a home
broadband customer next month. Share it with a `valid_until`, and remove what has expired from your own
SIEM, or the rule that matched an attacker in September blocks a stranger in December.

**Say what the indicator was seen doing.** "203.0.113.200" alone invites a block; "203.0.113.200, received
612 MB from a file server over HTTPS at 02:41 on 17 September, after SSH access" lets the receiver judge
relevance and avoid blocking something they depend on.

**Beware of shared infrastructure.** Addresses of large cloud providers, content delivery networks and
mobile carriers are used by thousands of customers at once, often behind address translation. An
indicator pointing at one of them blocks the innocent along with the guilty. Prefer domains, behaviour or
nothing.

**Defang what people will read.** Written in a report or a chat, an indicator is made inert so that nobody
clicks or connects by accident: `203.0.113[.]66`, `hxxps://files.example[.]com`. Machine-readable
formats such as STIX keep the real value, because a SIEM has to match it exactly.
