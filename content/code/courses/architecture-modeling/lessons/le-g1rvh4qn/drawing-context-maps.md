---
title: Drawing a context map
version: 1
---

**A context map draws the bounded contexts of a domain and, for each pair that integrates, which
side is upstream and how the two relate.** The `design-patterns` course explained what each
relationship means in its lesson 11; this section is about putting them on a page so that somebody
who was not in the modelling session can read them.

## It is not a container diagram

The first mistake is to treat the map as another picture of the services. **A context is a model and
the language that goes with it, not a deployable thing.** One context may be implemented by three
containers, and one legacy container may hold two contexts tangled together. The lines on a context
map are not calls: they are **dependencies between models and between the teams that own them**.
The question a map answers is *when this model changes, who has to adapt?*

That is why a context map is drawn with a different vocabulary, and why it is worth drawing even
when the container diagram exists.

## The conventions

There is no OMG standard for context maps, but the conventions from Eric Evans's book and later DDD
practice are widely shared:

- each **context** is a box or a rounded shape with the context's name, often with the owning team;
- each **relationship** is a line between two contexts, with a **U** at the upstream end and a **D** at
  the downstream end; changes flow from U to D;
- the **pattern** is written at the end it applies to, usually abbreviated:

| at the end | abbreviation | meaning |
| --- | --- | --- |
| upstream | **OHS** | open host service: one documented protocol for every client |
| upstream | **PL** | published language: a shared, documented format, often with OHS |
| downstream | **ACL** | anticorruption layer: the downstream translates the upstream's model |
| downstream | **CF** | conformist: the downstream takes the upstream's model as it is |
| both | **SK** | shared kernel: a small piece of model owned by both |
| both | **P** | partnership: the two plan together and succeed or fail together |
| pair | **C/S** | customer and supplier: the upstream plans for the downstream's needs |

Some teams draw an ACL as a small box on the downstream side of the line, as `design-patterns`
did. Both are fine; the legend says which.

## Reading direction without arrows

A map often has no arrowheads at all, because **the U and D already say the direction**, and an
arrowhead would invite the reading *calls*. The payment gateway is upstream of Carcará even though
Carcará calls it: the gateway's model decides, and Carcará adapts. A webhook from the gateway to
Carcará does not change that. Upstream is about whose model wins, not about who opens the connection.

## What makes a map useful

- **Every line names a pattern.** A line with no pattern says only *these talk*, which the container
  diagram already said.
- **The relationship the teams actually have, not the one they wish they had.** If Pricing ignores
  Sales's requests, the relationship is conformist, whatever the org chart says about customers.
  The map is a diagnosis first.
- **The owning team on each context.** Half of the map's value is knowing who to talk to.
