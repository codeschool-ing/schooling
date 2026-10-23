---
title: An ontology, not a method
version: 1
---

**Zachman's framework says what kinds of description exist and how they relate; it says nothing about
the order in which to produce them or how to make decisions.** Zachman himself insists on the word
**ontology**: a structured classification of what there is, like the periodic table, which
classifies the elements and does not tell a chemist what to mix.

## What follows from that

- **There is no starting cell.** A team can begin with *why* for the executive or with *what* for the
  engineer. The grid does not care; a method would.
- **It combines with any method.** TOGAF's ADM, from lesson 8, can be run while placing each of its
  deliverables in a Zachman cell. Many enterprise architecture teams do exactly that: TOGAF for the
  process, Zachman as the filing system.
- **It finds gaps, it does not fill them.** Placing an organisation's documents in the grid shows
  which cells are empty. Whether an empty cell matters is a judgement the grid cannot make.

## Two rules of the grid

Zachman states several rules for the framework; two are useful to anybody using it:

1. **Each cell is primitive.** A model in a cell answers one question for one audience. A diagram that
   mixes *what* and *how*, entities and the processes that act on them, is a **composite**: useful,
   often necessary, but it spans cells, and knowing which ones tells you what it is mixing.
2. **The columns have no order.** *What* is not more important than *why*. A framework that treats
   data as primary, as information systems work of the 1980s often did, is a choice the grid does not
   make for you.

## Composites are normal

Most real diagrams are composites, and that is fine. Lesson 3's container diagram shows applications
(*how*, as processing), data stores (*what*) and their placement in technology (*where*), at the
engineer's row. Lesson 4's activity diagram with swimlanes mixes *how* and *who*. The grid's value
is not to forbid them but to **name what they combine**, so that when a composite becomes hard to
read, you know which primitive to split out.

## The criticism, and the answer

The common criticism is that Zachman's framework is **too abstract to use**: thirty-six cells and no
instructions. That is accurate, and it is the point. An ontology used as a method fails, because it
has no steps; used as a checklist of **which questions have been answered for whom**, it is one of
the fastest ways to find out what an architecture description is missing. The next section does that
for this course.
