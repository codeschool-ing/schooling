---
title: Four questions before the first copy
version: 1
---

**The common picture is that storage is cheap, so you collect everything now and decide what it is
for later.** Storage is cheap. Everything around it is not: every row collected has to be moved,
checked, kept, read, paid for and, when it describes a person, protected. Collecting is a promise to
do all of that every day, for as long as the data is kept.

Caio's request shows the shape. On Tuesday he asks Davi for the dock sensor readings: every dock,
every minute, kept for good, because his demand model will want them. It sounds like one decision.
Davi answers it with four questions, and most of this lesson is a section or two on each.

| question | what it asks | for the dock sensors | section |
|---|---|---|---|
| **how much?** | rows a day, bytes a row, and how both grow | 150 docks, one reading a minute each | 03 |
| **how often?** | how old the data may be when somebody reads it | Caio retrains once a week | 04, 05 |
| **how good?** | what is checked on arrival, and against what | a reading from a dock that does not exist | 06, 07 |
| **at what price?** | storage, reading, moving, calling | the bill a dashboard can run up | 08 |

Underneath all four sits a fifth, which is not a technical question: **may we have it at all?** A
sensor reading describes a dock. A ride describes a person: where they were, and when. Section 09
is about the difference.

## They are not four separate questions

The answers multiply. Frequency decides how many runs there are, and every run is a chance to fail:
a copy made every minute has 1,440 of them a day, where a nightly copy has one. Volume decides how
much each run moves and checks. Volume times how long it is kept times how often it is read is most
of the bill. **A change to one answer moves the other three**, which is why
they are asked together and before the first copy, not one at a time as each becomes a problem.

None of them has a right answer in general. Each has a right answer for one question somebody is
asking, which is why the first thing Davi asks Caio is what the model is for.
