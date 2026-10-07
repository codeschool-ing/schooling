---
title: SAFe, the Scaled Agile Framework
version: 1
---

SAFe is the most widely adopted scaling framework in large companies, and the one most often criticised. It was created by Dean Leffingwell and first published in 2011; it is maintained by his company, Scaled Agile, which also runs the certifications. Version 6.0 appeared in 2023. It is large on purpose: where the Scrum Guide is thirteen pages, SAFe is a website of hundreds of articles, roles and diagrams, and an organisation is expected to pick the parts it needs.

## The release train

SAFe's central unit is the **Agile Release Train**, or ART: a long-lived team of agile teams, typically **50 to 125 people**, that plans, builds and delivers together around one value stream — the series of steps by which the organisation delivers something a customer pays for. The teams on a train use Scrum or Kanban internally. What the train adds is a shared cadence: every team's iterations start and end on the same days, so that the train can plan, integrate and demonstrate as one.

Three roles exist at train level, on top of the teams' own:

- the **Release Train Engineer**, who facilitates the train's events and removes impediments across teams — a Scrum Master for the train;
- **Product Management**, who own the train's backlog of features and decide what the train builds — the Product Owner role one level up;
- the **System Architect**, who shapes the technical direction across the teams.

The System Architect is the role most relevant to this course's readers. SAFe gives it an explicit job: building the **architectural runway**, the existing code, components and infrastructure that let upcoming features be built without large delays. Runway is consumed by every feature and has to be extended deliberately, as work on the backlog like any other, or the train slows down feature by feature.

## Four configurations

SAFe comes in four configurations, from smallest to largest:

| configuration | what it adds |
|---|---|
| Essential | one or more release trains; the core of the framework |
| Large Solution | coordination across several trains building one large system, such as a vehicle or a bank's core |
| Portfolio | strategy and funding: which value streams exist and how much each receives |
| Full | all of the above |

Most organisations start with Essential and add the Portfolio level when funding becomes the problem, which it usually does: an annual project budget sits badly beside teams that plan every ten weeks.

## Where it fits

SAFe fits large organisations where many teams genuinely depend on each other, the business wants plans it can see a quarter ahead, and the existing structure is not going to be redesigned. Its strength is that it gives such an organisation a common vocabulary and a regular moment when everybody plans together. Its cost is weight: roles, events and artefacts that each need people and time, and that can become a new bureaucracy with agile names. The last section of this lesson returns to that criticism.
