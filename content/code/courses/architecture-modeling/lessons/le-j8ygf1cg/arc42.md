---
title: arc42, a template for the whole architecture
version: 1
---

**arc42 is a free template for documenting a software architecture, in twelve parts, created by
Gernot Starke and Peter Hruschka.** It does not tell you how to design; it tells you what a reader
will look for in an architecture document, and gives each thing a place. Its strength is that a
reader who has seen one arc42 document can find their way in any other.

## The twelve parts

| | part | what goes in it | where in this course |
| --- | --- | --- | --- |
| 1 | **introduction and goals** | the purpose, the top quality goals, the stakeholders | lessons 6 and 7 |
| 2 | **constraints** | what was decided by others: laws, platforms, conventions | lesson 6 |
| 3 | **context and scope** | the system and its environment, business and technical | lesson 3's system context |
| 4 | **solution strategy** | the few fundamental decisions and the reasons | lesson 5's most important records |
| 5 | **building block view** | the static structure, level by level | lesson 3's containers and components |
| 6 | **runtime view** | how the blocks behave in important scenarios | lesson 2's sequences, lesson 4's flows |
| 7 | **deployment view** | the infrastructure and how blocks map onto it | lesson 2's deployment |
| 8 | **cross-cutting concepts** | rules applied everywhere: security, logging, error handling, the domain model | lessons 2 and 4 |
| 9 | **architecture decisions** | the decision log, or links to it | lesson 5 |
| 10 | **quality requirements** | the quality tree and scenarios | lesson 6's utility tree |
| 11 | **risks and technical debt** | known problems, ranked | lesson 13 |
| 12 | **glossary** | the terms, with one meaning each | `design-patterns` lesson 11's ubiquitous language |

The right-hand column is the point of showing the table here: **arc42 is a container for the
artefacts this course has already taught you to make**. It adds very little of its own except an
order and a set of empty headings, and the empty headings are the useful part.

## Using it without filling it

The template's own advice is to keep the parts short and **leave out what nobody needs**. A part
can be one sentence and a link. Carcará's ticketing document is eleven pages: part 8 is the
longest, because the cross-cutting rules about offline boarding and idempotency are what new
engineers most often break; part 2 is three lines.

What the template does well is make absences visible. Carcará's first draft had nothing in part
11. Writing *none known* under *risks and technical debt* felt wrong to everybody in the room, and
within ten minutes there were six entries, starting with Frota's nightly export, which has no retry.

## C4, arc42 and decision records together

The three combine with no friction, which is why many teams use exactly this set:

- **C4 diagrams** go in parts 3, 5 and 7;
- **decision records** stay in their own folder and part 9 links to the index;
- **arc42** gives the headings that hold it together, and part 1's quality goals point to
  part 10's scenarios.
