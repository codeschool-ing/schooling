---
title: Versioning a contract
version: 1
---

A contract that can never change is a contract nobody will sign. Data needs to evolve; the point of
the contract is that it evolves **without surprising anybody**. Most teams borrow semantic versioning
from software, with the rules written for data:

| change | version | why |
|---|---|---|
| a new optional field at the end | **minor**: 1.0.0 → 1.1.0 | a consumer that ignores unknown fields keeps working |
| a fix to a description, a tighter quality rule | **patch**: 1.0.0 → 1.0.1 | nothing a consumer reads changes |
| a field removed or renamed | **major**: 1.0.0 → 2.0.0 | every consumer that reads it breaks |
| a type changed | **major** | the parse, the sum, the comparison may all change |
| a meaning changed with the name kept | **major**, and the most dangerous | nothing breaks, everything is wrong |

The last row is section 6's second break. A change of meaning is always major, even when the schema is
byte for byte the same, which is exactly why it has to be described in words somewhere a reviewer
reads.

## Two versions at once

A major change is not made by editing the view. It is made by **publishing the new version beside the
old one** — `share.delivery_feed_v2` next to `share.delivery_feed` — announcing a date, and removing
the old one when every consumer has moved. For a while, both exist and both are checked against their
own contracts. It costs a view and a few weeks; the alternative costs a morning of vans loaded for half
the parcels.

## Privacy changes are major too

A field that adds personal data, a new purpose, a longer retention at the consumer, a new country:
each changes what Ipê is sharing and why. Under this course's rules they are **major** changes even if
no consumer's code would break, because they need the owner's decision and, often, the DPO's — and
because for a processor like Rota Certa they are changes to Ipê's instructions, which is what article
39 makes the processor follow.
