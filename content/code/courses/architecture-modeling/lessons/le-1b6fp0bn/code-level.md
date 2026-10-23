---
title: Level 4, code, and why it is rarely drawn
version: 1
---

**The fourth level shows how one component is implemented: its classes, interfaces, functions or
tables.** It is usually a UML class diagram, or an entity-relationship diagram for a data store, and
C4 says plainly that you should draw it only when it adds something the code does not.

## Why it is optional

Three reasons, each enough on its own:

- **The code already says it, more precisely.** An IDE shows a class hierarchy, a call graph and
  every reference, and it is never out of date.
- **It goes stale the fastest.** Renaming a class or extracting a method changes the code level;
  nobody updates a diagram for that.
- **The audience is small.** Only the people working inside that component need it, and they have
  the code open.

## When it earns its place

There are cases where a code-level picture says something the code hides:

- **A domain model that the business also reads.** The booking aggregate from lesson 2 is a code
  level diagram of the booking component, and it earns its place because product people and
  engineers argue about it.
- **A pattern that spans many files.** The way the payment adapter implements a port defined by the
  booking service is the dependency inversion from `design-patterns`, and one small diagram shows
  it faster than five files.
- **A data model with constraints.** The tables, keys and cardinalities of the booking database are
  the same shape as the class diagram, and the database is shared by more people than the code.

In each case, draw **the five or six elements the question needs**, not the component's whole
contents, exactly as lesson 2 did.

## The consistency rule

Whatever the level, the rule from the component diagram holds: **an element at one level should be
traceable to an element at the level above**. Every class in a code-level diagram belongs to a
component; every component to a container; every container to a system. When a class cannot be
placed, either the diagram is missing a component, or the code has grown something the
architecture never decided, which is worth knowing either way.
