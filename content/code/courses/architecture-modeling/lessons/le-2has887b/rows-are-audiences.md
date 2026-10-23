---
title: Rows are audiences, not levels of detail
version: 1
---

**The most common misreading of the Zachman grid is that each row is the one above it with more
detail.** It is not. Each row is a different description, for a different person, and moving down a
row changes what is being described, not only how finely.

## The building analogy

Zachman built the framework from how other industries describe complex things. For a building:

- the **owner** needs a sketch of what the building is for and roughly what it contains;
- the **architect** needs plans and elevations, in the language of rooms and spaces;
- the **builder** needs construction drawings, in the language of beams and pipes;
- the **subcontractor** needs shop drawings for one part, in the language of parts and fittings.

The builder's drawing is not a more detailed version of the owner's sketch. It answers questions the
owner never asked, in words the owner does not use. Each one is **complete for its reader** at its
own level, and each is derived from the one above by a change of language, not by zooming in.

## Zooming and changing rows are different moves

This is where Zachman and lesson 3's C4 model meet and differ:

- **C4's levels zoom.** A container diagram and a component diagram are the same kind of
  description, for technical readers, at two magnifications.
- **Zachman's rows translate.** Row 2's *how* is a business process in business words; row 3's *how*
  is the logical system process; row 4's *how* is the physical design with technologies. Each is a
  different model.

So the whole of C4 sits roughly in rows 3 and 4, and zooms inside them. The business manager's
process model of row 2 is a different kind of thing altogether, which is why lesson 4's BPMN and
lesson 7's business analysis exist.

## Why it matters in practice

Mistaking the rows for detail produces a familiar failure: a business manager handed an engineer's
diagram *because it is more complete*. It is not more complete for that reader; it is in the wrong
language. Lesson 14 turns this into the rule for presenting architecture: **change the row, not the
zoom**, when the audience changes.
