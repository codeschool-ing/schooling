---
title: SPACE, five dimensions of one question
version: 1
---

"How productive is this team?" sounds like it should have one answer, and every attempt to give it one has failed in the same way: the single number captures one thing and the team learns to produce that thing. Lines of code produced long programs; tickets closed produced small tickets; story points produced inflated estimates. **Productivity is not one quantity**, and the most useful recent work on the subject starts from that.

In 2021, Nicole Forsgren, Margaret-Anne Storey, Chandra Maddila, Thomas Zimmermann, Brian Houck and Jenna Butler published *The SPACE of Developer Productivity* in ACM Queue. Forsgren is the same researcher behind the DORA work of lessons 5 to 7. The paper proposes five dimensions, and its acronym is their initials.

| dimension | what it asks | an example measurement |
|---|---|---|
| **S**atisfaction and well-being | how fulfilled, healthy and happy are people with their work? | a regular survey; whether people would recommend the team |
| **P**erformance | what did the work achieve? | outcomes: reliability, customer satisfaction, adoption |
| **A**ctivity | how much was done? | deployments, reviews, items finished, incidents handled |
| **C**ommunication and collaboration | how well do people and teams work together? | review turnaround, how easily information is found, onboarding time |
| **E**fficiency and flow | can work move without interruption and hand-offs? | cycle time, time in queues, uninterrupted focus time |

## Three levels, too

The paper adds a second axis: each dimension can be measured for **an individual, a team or group, or the whole system**. Activity for an individual is the commits they made; for a team, the items it finished; for the system, the deployments across the organisation. The levels behave differently, and the most damaging misuse in this lesson, its fourth section, lives at the first one.

## What the course has already measured

Most of what lessons 1 to 7 computed sits in two of the five dimensions. Cycle time, waiting time, flow efficiency and work in progress are **efficiency and flow**. Deployment frequency and items finished are **activity**. Change failure rate and time to restore lean towards **performance**, in the narrow sense of the system's reliability.

That leaves three dimensions the Billing team's files never touched: how people feel about their work, how well they collaborate, and what the work achieved for anybody. **A report built only from the files would describe half of the team's productivity and present it as the whole**, which is exactly lesson 6's warning about the DORA metrics, generalised.
