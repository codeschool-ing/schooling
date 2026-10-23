---
title: A notation is a contract with the reader
version: 1
---

**A notation is an agreement, made before the reader looks, about what each kind of mark means.** A
standard notation such as UML makes that agreement once, for everybody who learnt it. An informal
one makes it on the page, in a legend. Both work. What does not work is a drawing that has no
agreement at all, where the reader has to guess the rules from the marks.

## Formal, informal and the space between

| | where the meaning is written | good for | the price |
| --- | --- | --- | --- |
| **a standard notation** (UML, BPMN, ArchiMate) | in a specification the reader studied | readers who know it; precise claims about structure and behaviour | readers who do not know it see boxes with odd arrowheads, and a diamond on the wrong end changes the meaning |
| **a light convention** (C4) | in a short set of rules plus a legend on each diagram | mixed audiences; technical detail without a manual | it says little about behaviour; for that it borrows UML |
| **boxes and lines** | only in the legend, if there is one | a quick sketch, a whiteboard, a first draft | without a legend it is decoration, whatever the intent |

None of these is better in general. **The right notation is the one your reader can read**, with
enough precision for the question. A UML sequence diagram is the right picture for an engineer
debugging a timeout and the wrong one for Celeste, the operations director, who wants to know
whether a bus can leave when the payment provider is down.

## The legend is the contract made visible

A legend, also called a key, lists every kind of mark the diagram uses and what it means. Two
common objections are both wrong:

- *"Everybody knows what a box means."* Each of them knows something different, which is the
  problem a legend solves.
- *"It clutters the picture."* A legend takes a corner. Its absence costs every reader a guess for
  every mark.

A good legend covers **element types** (person, service, database, external system), **line styles**
(solid for synchronous calls, dashed for asynchronous messages, if that is the convention),
**colours** and **boundaries**. If a kind of mark appears only once, it still needs an entry.

## One meaning per mark, across the whole document

The contract holds across a set of diagrams, not only inside one. If a dashed line means
*asynchronous* on the container diagram and *planned, not built yet* on the deployment diagram, the
reader who has seen the first will misread the second. Carcará solved this the dull way: one short
page in the architecture repository called *How we draw*, which every diagram links to. It fits on
one screen:

- people are rounded boxes with a head; our services are boxes in the accent colour; anything we do
  not run is grey;
- a solid line is a call that waits for an answer; a dashed line is a message that does not;
- every line has a verb, and the protocol when the reader is technical;
- a boundary is drawn dashed and named in its top-left corner;
- every diagram has a title that says what it shows and the date it was last checked.

**A notation of your own is fine if you write it down.** What causes trouble is a private one: the
conventions are all in the author's head, consistent and invisible, and the first reader to learn
them is the one who asks.
