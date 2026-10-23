---
title: Which view for which room
version: 1
---

**The first decision in presenting architecture is which view to show, and it is decided by what
the people in the room decide, not by what the architect finds interesting.** Lesson 1 said that a
diagram answers a question. A presentation is the same rule with an audience attached: the question
is theirs, so the view has to be the one that answers it.

## The week after the review

The review of lesson 13 ended on a Friday. In the following week Tainá had to present it three
times:

| room | who | what they decide | the view she chose |
| --- | --- | --- | --- |
| **Monday, the directors** | Celeste and the other directors | money, dates, what the company risks at São João | the system context of lesson 3, with the 26 stations drawn as one element and the second link marked on it |
| **Wednesday, product** | Otávio and the product managers | what is built before the peak, and what waits | the context again, plus one dynamic diagram: a passenger's purchase on the busiest morning, numbered step by step |
| **Thursday, engineering** | the forty engineers | how the changes are built, and who builds them | the container diagram, a sequence diagram of two phones uploading scans for one ticket, and the state table of lesson 4 |

None of the three rooms saw the diagram another room saw first. The directors never saw a container,
and the engineers did not need the context explained to them. **Showing the engineers' view to the
directors is the most common mistake, and it comes from the architect's pride in the detailed
picture**, which is the one they spent most time on.

## Where the answer comes from

The course already gave you three ways to choose:

- **C4's zoom levels** (lesson 3): the context for anybody, containers for people who build or run
  the system, components for the team that owns one container.
- **Zachman's rows** (lesson 10): each row is an audience, from the planner at the top to the
  builder at the bottom. A row tells you the vocabulary as well as the level.
- **ArchiMate's viewpoints** (lesson 9): a viewpoint is a view designed for a stakeholder's
  concern, which is exactly the problem of a presentation, already solved for a model.

They agree more than they differ. The higher the reader's decisions, the fewer boxes and the less
technology on the page.

## When the room is mixed

Some rooms hold a director and three engineers at once. Two habits help:

- **Start at the highest level anybody in the room needs**, and go down one level only for the part
  the decision rests on. The engineers will follow the context; the director will not follow the
  containers.
- **Say aloud which level you are moving to**, *now one level down, into the ticketing system*, so
  the people who do not need it know they can let it pass.

Adapting a message to an audience in general, beyond diagrams, is `architect-communication`
lesson 3, later in this track. This lesson keeps to what is particular to architecture: the
model, its views and its notation.
