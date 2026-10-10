---
title: At least three dimensions, and at least one survey
version: 1
---

The SPACE paper does not offer a formula. It offers rules for choosing measurements, and two of them do most of the work.

## Measure at least three dimensions

A single dimension can always be improved by sacrificing the others, and the sacrifice will not show. More activity can come from longer hours, which damages well-being; faster flow can come from skipping reviews, which damages collaboration and, later, performance. **Measurements from at least three dimensions, chosen to pull against each other, make a trade visible**: if activity rises while satisfaction falls, somebody is paying for the activity.

For the Billing team, a sensible first set would be:

- **efficiency and flow**: cycle time and its 85th percentile, from lessons 1 to 4;
- **performance**: the change failure rate and time to restore, from lesson 5;
- **satisfaction and well-being**: a short quarterly survey, this lesson's fifth section.

Three numbers and a survey, each from a different dimension, each able to show a cost the others would hide.

## Include perceptual measures

The second rule is that **at least one measurement should be what people report, not what a system records**. Systems record events; they cannot record that a developer spent the morning waiting for a test environment, that a review was technically fast and useless, or that the team is quietly exhausted. People can.

Perceptual measures have a reputation for being soft, and the reputation is half earned: a survey answer is an opinion. But opinions about one's own experience are the only data there is about that experience, and they disagree with system data in useful ways. A team whose cycle time improved while its members report that they cannot focus is a team where something has not been measured yet.

## Put the measures in tension

The best set is one where improving any single measure honestly would show up in the others. Lesson 7's habit of pairing each metric with the one it can be traded against is the same idea, applied across dimensions rather than inside DORA:

| if this improves | watch whether this gets worse |
|---|---|
| activity: items finished | well-being: energy, hours, the on-call load |
| flow: cycle time | collaboration: review depth, knowledge shared |
| performance: fewer failures | flow: changes held back out of fear |

None of this produces a single productivity score, and that is the point of the framework. **A team's productivity is a profile, read across dimensions, and a profile cannot be ranked**, which protects it from most of what lesson 7 described.
