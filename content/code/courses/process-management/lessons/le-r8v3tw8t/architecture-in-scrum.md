---
title: Where architecture fits in a Sprint
version: 1
---

The Scrum Guide does not mention architecture, design documents or architects. That silence is read two ways, and both are wrong: that Scrum teams do no up-front design, and that architecture has to happen outside Scrum, in a separate phase. What the guide actually leaves open is **how** the design work is done and recorded, which is the same freedom it gives every other practice.

## Architecture as backlog work

Design work that the product needs goes into the Product Backlog like any other work, ordered by the Product Owner against features. An item such as *"choose and prove the way bookings are stored so that two clinics never see each other's patients"* is valuable because it removes a risk, and lesson 12 shows how that value is weighed against features. The Product Owner does not need to understand the design; they need to understand what happens to the product if it is not done.

When the team does not know enough to estimate a piece of work, it can run a **spike**: a short, time-boxed investigation whose output is knowledge rather than a feature — a prototype that answers *"can the calendar library handle the clinic's recurring appointments?"*. The word comes from Extreme Programming, which lesson 4 covers, and the practice fits Scrum's backlog unchanged.

## Architecture in the Definition of Done

Quality attributes that every change must keep belong in the Definition of Done, as this lesson's fifth section argued: a response-time limit, a logging format, a security scan. That puts the architect's decisions into every Sprint without a separate task for each.

## Where the architect sits

An architect who works with Scrum teams is in one of two places. **On a team**, as one of the Developers, the architect takes items from the Sprint Backlog like everybody else and leads design discussions from inside. **Across teams**, serving several, the architect attends the refinement and reviews where design is decided, writes the decisions down — architecture decision records are the usual form — and is careful not to become a gate every item has to pass. Lesson 5 returns to this, because it is the normal situation once there is more than one team.

## Enough design, early enough

The practical question is how much to decide before the first Sprint. The answer agile writers converged on is **the decisions that would be expensive to reverse**: the data store, the boundaries between services, the way identity works, the hosting platform. Those get a deliberate decision in the first Sprints, often with a spike behind each. Everything that is cheap to change later is left until the team knows more, which is the cone of uncertainty from lesson 1 put to work.
