---
title: Where threats come from
version: 1
---

When people picture a threat they picture a hacker in a hoodie. That picture misses most of the
threats a small business actually meets. **Threats come from three sources, and the deliberate
one is not always the largest.**

| source | examples at the shop | what defends against it |
|---|---|---|
| **natural** or environmental | flood, fire, heat wave, power cut | location, power backup, off-site copies |
| **accidental** | a deleted folder, a wrong price imported, a laptop left on a bus | training, backups, review of changes |
| **deliberate** | a criminal, a fraudster, an angry former employee | most of this course |

The accidental row deserves more respect than it gets. A mistake has no intention behind it, so
it never gives up, never gets bored and is never deterred by the thought of being caught. A
backup policy designed only against attackers can still fail the day somebody deletes the wrong
folder and nobody notices for a month.

### The deliberate ones: threat actors

A person or group behind a deliberate threat is a **threat actor**. They differ in what they
want and in what they can do, and those two differences matter more than the name:

| actor | wants | typical capability |
|---|---|---|
| opportunistic criminal | money, from whoever is easiest | automated tools aimed at the whole internet |
| organised crime | money, at scale: ransomware, fraud | skilled, funded, patient |
| insider | revenge, money, or nothing (a careless employee) | already has access, which is the danger |
| hacktivist | attention for a cause | defacement, leaks, floods of traffic |
| nation-state | intelligence, disruption | the most capable, and rarely interested in a bookshop |

**The shop's realistic adversary is the first row.** Nobody targets a nine-person bookshop by
name; automated tools sweep the internet for any login page with a default password and any server
missing a patch, and the shop is simply on the internet. That changes the defence: against an
opportunist, being slightly harder than average is enough, because they move on to an easier
target. Against a determined actor it is not, and lesson 4 explains why layers matter then.

The insider row is the uncomfortable one. Nine people already have accounts, keys and the trust
of their colleagues. Most insider incidents are carelessness rather than malice, and the controls
are the same either way: give each person only what their job needs (lesson 6) and record who did
what (lesson 1's accountability).

A **threat vector**, or attack vector, is the path a threat uses to reach the asset: email, a
public web page, a USB stick, a phone call to the help desk. Listing the vectors that reach an
asset is how a defender finds where to put controls. `attacks-threats` takes the deliberate
vectors one at a time; this course needs only the idea that they exist.
