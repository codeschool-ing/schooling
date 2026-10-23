---
title: When not to draw
version: 1
---

**A diagram costs drawing, reading and, above all, keeping true, so it has to carry something a
sentence cannot.** Many pictures in architecture documents restate the paragraph next to them, and
a picture that repeats its caption is worse than none: it costs the same upkeep and teaches nothing.

## What a picture carries that a sentence does not

The rule this platform uses for its own lessons is a good one for architecture documents too. **A
diagram earns its place when it carries one of four things:**

| | what | a Carcará example |
| --- | --- | --- |
| **a sequence in time** | steps where a later one depends on an earlier one returning | the passenger's request, the seat hold, the charge, the confirmation, in that order |
| **a nesting or a boundary** | what is inside what, and what crosses the line | which services run in Carcará's cloud account and which belong to the payment company |
| **a count** | many things at once, which prose can only assert | 300 buses' phones syncing their ticket lists at 05:00 |
| **two axes at once** | where the shape itself is the argument | ticket sales per hour against the week of São João |

If what you want to say is none of those, a sentence or a table will probably say it better. *The
ticketing API writes to the booking database* is one sentence; drawn, it is two boxes and an arrow
that the reader decodes back into the same sentence.

## Diagrams that should not exist

- **The diagram that duplicates the code.** A class diagram of every class in a service is out of
  date by the next pull request, and the code says it better. If the structure matters, generate it
  from the code, as lesson 12 shows, or draw only the five classes the reader needs.
- **The diagram nobody will update.** If no one owns it, it will be wrong within months, and a wrong
  diagram does more harm than an absent one, because people trust a picture. Lesson 11 is about
  ownership and deletion.
- **The diagram for the document's sake.** A template asks for an architecture diagram, so one is
  drawn. If the question the template expects it to answer is not your reader's question, write
  that down instead.

## A sketch is not a document

None of this applies to a sketch. Drawing on a whiteboard or a piece of paper while thinking, or
while talking with a colleague, is one of the most useful things an architect does, **and the sketch
is meant to be thrown away**. The rules in this lesson are for the diagram you hand to somebody who
was not there. A photographed whiteboard pasted into a document is not that diagram; it is a sketch
somebody forgot to redraw, and it carries all the private conventions of the people who were in the
room.

**Draw it yourself.** Take an architecture document you have access to and look at each diagram in
it. For each one, decide which of the four things it carries. If it carries none, write the
sentence that would replace it, and see whether anything was lost.
