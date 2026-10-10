---
title: "Context maps: how the models meet"
version: 1
---

**A context map is a drawing of the bounded contexts and of the relationship between each pair
that talks: who depends on whom, and who adapts when the other changes.** The contexts are the
nouns; the map is about the verbs. It is the strategic document that a new developer needs on their
first day, because it says which changes are theirs to make and which have to be negotiated.

The wrong idea is that integration is a technical detail: an HTTP call here, a shared table there.
Every connection between two models is also a relationship between the people who own them. When
the catalogue renames a field, somebody's code breaks, and the map is where you decide in advance
whose problem that is. In DDD's vocabulary the context that others depend on is **upstream**, and
the one that depends is **downstream**. Changes flow down; complaints flow up.

## The relationships

Evans named most of these, and the names have stuck because each one is a different answer to
"who adapts?":

| relationship | who adapts to whom | when it fits |
|---|---|---|
| partnership | both, together; they succeed or fail as one | two teams that plan their releases jointly |
| shared kernel | nobody alone: a small piece of model is owned by both, and changed only by agreement | a value type both depend on and neither wants to copy |
| customer/supplier | the upstream plans for the downstream's needs | the downstream's needs count in the upstream's plans |
| conformist | the downstream adopts the upstream's model as it is | the upstream will not change for you, and its model is good enough |
| anticorruption layer | the downstream translates the upstream's model into its own | the upstream will not change, and its model would damage yours |
| open host service, published language | the upstream offers one documented protocol for everybody | many downstreams, so one-to-one deals would not scale |
| separate ways | nobody: the two do not integrate at all | the cost of connecting is higher than the benefit |

## The library's map

@@fig:l11-context-map@@

Read the map one line at a time.

**Catalogue to lending is customer/supplier.** The lending desk shows titles and authors, so it
depends on the catalogue. The catalogue's owners treat lending as a customer: before changing what
a catalogue entry looks like, they ask what the desk screen needs. Without that agreement the
relationship slides into conformist by default, and lending has no say.

**Catalogue and acquisitions share a kernel: the ISBN.** Both need to parse, validate and format
ISBNs, and two copies of that code would disagree one day about a hyphen. So one small module is
owned by both, and a change to it needs both to agree. A shared kernel works while it stays small;
the moment it grows a `Book` class, it has become the one enterprise model again.

**The payment provider to lending is conformist.** The provider's model of a payment, with its own
statuses for pending, confirmed and refunded, is what it is, and the library is one customer among
thousands. Its model is also reasonable, so lending simply uses its words for payment states. Being
conformist is not a defeat when the upstream model is good; it saves a translation nobody needs.

**The national bibliographic service to catalogue goes through an anticorruption layer.** The
service will not change for one library, and its model is a poor fit: abbreviated field names,
titles in capitals, authors written surname first. Adopting it would put those habits into the
catalogue's own code. The next section builds the layer.

## What the map is for

A map that matches the code is a planning tool. A downstream team can see that it is conformist
and decide whether that is still acceptable. A team about to add an integration can see that it is
creating a new upstream dependency, and choose the relationship before the first line of code
chooses it for them. **The map describes the organisation as much as the software**, which is
Conway's observation from 1968: systems end up shaped like the communication between the teams that
build them.

`architecture-modeling`, the course after this one, draws context maps as models in their own
right. Here a sketch on a page is enough, as long as every line on it has a name from the table.
