---
title: Trust by location
version: 1
---

Lesson 5 ended with the shop's network divided into zones, and with a warning: the perimeter cannot
stand alone, because attackers get inside without crossing it. This lesson is about the assumption
that makes that dangerous, and it is easiest to see in one sentence most networks still live by:

> **if a request comes from inside, it is probably one of us.**

That is **implicit trust**, or trust by location. The network address a request comes from is used
as evidence of who sent it. It shows up everywhere once you look:

| where | the implicit trust |
|---|---|
| an intranet page with no login | "only staff can reach it" |
| a database that accepts any connection from the server segment | "only our servers are there" |
| a printer's admin page with no password | "it is on the internal network" |
| a VPN that, once connected, reaches everything | "they logged in once, so they are fine" |

Every row fails in the same situation: **something on the inside is not what it should be.** A
staff laptop infected by an email attachment is on the inside. So is a visitor's phone on the wrong
Wi-Fi, a contractor's machine plugged into a spare socket, and a server that was compromised last
week and has been quiet since. Each of them inherits all the trust the location carries.

The other direction fails too. A member of staff working from home with their own correct password
is outside, and a policy based on location treats them like a stranger. That pushes people towards
workarounds: a VPN left connected all day, or files emailed to a personal address so they can be
opened at home.

### Where the name came from

The term **Zero Trust** was coined by John Kindervag at Forrester Research in 2010, as a reaction
to exactly this model. Google described its own move away from a privileged internal network in a
series of papers from 2014 under the name **BeyondCorp**: its staff reach internal applications
from any network, and the network they are on grants nothing. In 2020 the US National Institute of
Standards and Technology published **SP 800-207, Zero Trust Architecture**, which is the reference
most organisations now use and the source of the vocabulary in the next two sections.
