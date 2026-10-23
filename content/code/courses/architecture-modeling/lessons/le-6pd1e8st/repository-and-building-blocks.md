---
title: Building blocks, the repository and the continuum
version: 1
---

**TOGAF describes an architecture as a set of building blocks, keeps them in an architecture
repository, and classifies reusable ones along an enterprise continuum.** Three ideas, each simpler
than its name.

## Building blocks

A **building block** is a package of functionality that meets a business need, with defined
boundaries and interfaces. TOGAF separates two kinds:

- an **architecture building block (ABB)** says **what** capability is needed, independent of any
  product: *a ticket validation capability that works offline*;
- a **solution building block (SBB)** says **how** it is provided, with a product or a component:
  *the boarding app on Android phones with a local SQLite store, synchronised every 15 minutes*.

The split is the same move as lesson 6's *what, not how*. ABBs are written in phases B to D;
SBBs appear in phase E, where the solutions are chosen. One ABB can be met by different SBBs in
different places, which is how a company with two kinds of phone keeps one architecture.

## The architecture repository

The **repository** is where the architecture's outputs live: principles, models, standards, decision
records, the building blocks, the reference material and the governance log. The standard describes
its parts in detail. For Carcará, the architecture repository is a Git repository with folders for
each of those, the same place lesson 5 put the decision records, and lesson 11 is about keeping it
alive.

## The enterprise continuum

The **enterprise continuum** is a way of classifying architecture assets by how generic they are,
from the universal to the specific to one organisation:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l08-continuum\" aria-label=\"The enterprise continuum as an arrow from generic on the left to specific on the right, with four kinds of architecture along it: foundation architectures, common systems architectures, industry architectures and organisation-specific architectures. Reuse means looking further left before designing.\"><defs><marker id=\"l08-continuum-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 110.0 L690.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l08-continuum-am-fill-paper-dim)\"></path><text x=\"30.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">generic</text><text x=\"690.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">specific</text><rect x=\"35.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Foundation</text><text x=\"110.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">true of almost anybody</text><circle cx=\"110.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><rect x=\"202.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"277.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Common systems</text><text x=\"277.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">identity, payments</text><circle cx=\"277.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><rect x=\"369.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"444.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Industry</text><text x=\"444.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">transport ticketing</text><circle cx=\"444.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><rect x=\"536.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"611.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Organisation</text><text x=\"611.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">Carcará's own</text><circle cx=\"611.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">before designing, look further left</text></svg>", "caption": "Carcará did not invent offline ticket validation: an industry reference design existed, and reading it saved weeks."}
```

- **foundation architectures**: generic, true of almost any enterprise, such as a reference model of
  common technology services;
- **common systems architectures**: patterns reused across many domains, such as a standard way to
  do identity or payments;
- **industry architectures**: shared within an industry, such as a reference model for transport
  ticketing;
- **organisation-specific architectures**: Carcará's own.

The point of the continuum is **reuse**: before designing something, look further left to see if a
more generic architecture already solves it. Carcará did not invent offline ticket validation;
transport operators have reference designs for it, and reading one saved weeks in phase C.

## Architecture principles

The Preliminary phase writes **principles**, short rules that guide decisions. TOGAF gives them a
fixed shape: a **name**, a **statement**, a **rationale** and the **implications**. Two of Carcará's
eight:

> **Boarding works without a network.** *Statement:* no capability needed to board a bus may depend
> on a live connection. *Rationale:* 40% of departures leave from stops with poor signal.
> *Implications:* every boarding feature needs an offline design and a sync rule.

> **One record of a ticket.** *Statement:* ticketing is the only system that creates or changes a
> ticket. *Rationale:* two records of one ticket disagree. *Implications:* counter sales go through
> ticketing; the back office's own ticket table is retired.

A principle with no implications is a slogan. The implications are what let a reviewer use it.
