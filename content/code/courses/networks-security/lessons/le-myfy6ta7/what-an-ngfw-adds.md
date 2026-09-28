---
title: What else a next-generation firewall bundles
version: 1
---

"Next-generation" is a marketing term, and it covers several unrelated features sold in one box.
Each is worth recognising by what it actually does:

| feature | what it does | where this course covers the mechanism |
|---|---|---|
| application identification | names the protocol from the payload | this lesson |
| user identity | ties an address to a signed-in person, so a rule can say "finance" instead of a subnet | lesson 22 |
| intrusion prevention | drops traffic that matches a known attack signature | lessons 14 and 15 |
| URL and category filtering | allows or blocks by the site's category, from the SNI or the HTTP host | lesson 9 |
| TLS inspection | decrypts to read the content | this lesson |
| threat intelligence feeds | blocks addresses and names a vendor has seen misbehave | lesson 23 |
| sandboxing | runs downloaded files somewhere safe to watch what they do | lesson 9 |

**Every item costs throughput.** A firewall that only matches headers forwards at close to the
speed of its hardware. Each feature that reads payloads is software doing work per packet, and
vendors quote a separate, smaller throughput figure with inspection on. Sizing a firewall by the
headline number and then turning on every feature is the common way to find this out.

## Where it sits

An NGFW belongs where the traffic worth reading crosses a boundary: the internet edge, and between
zones of different trust (lesson 4). It is the wrong tool deep inside a data centre, where the
volume is highest and most flows are between machines that already trust each other; lesson 21
handles that with rules on the machines themselves.

**The layers stack rather than compete**: the stateless filter of lesson 1 at the border throws away
what can never be legitimate, the stateful firewall decides which conversations may exist, and the
inspection engine reads the few that the policy cares about.
