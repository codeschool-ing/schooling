---
title: Roles: who commands, who fixes, who talks
version: 1
---

The commonest failure in an incident is not technical. It is **everybody debugging and nobody in
charge**: five people with five theories, two of them changing the same thing, and the customers'
questions unanswered because the only people who could answer are in a terminal. The fix, borrowed
from how fire services run emergencies, is a small set of roles that are assigned at the start and
written where everybody can see them.

| role | does | does not |
|---|---|---|
| **incident commander** (IC) | owns the incident: sets priorities, assigns work, decides, keeps the timeline moving | debug, type commands, or disappear into a dashboard |
| **operations lead** | investigates and changes the system, with the people they pull in | talk to customers or decide priorities |
| **communications lead** | writes the updates: to the company, to support, to the status page | investigate |
| **scribe** | records what is tried, decided and observed, with times | anything else |

In a small team one person may hold two roles, and the first responder is IC until they hand it over
out loud: *"I am handing incident command to Bruno."* What must never happen is the IC holding the
operations role as well during a SEV-1. **The commander's value is in not having their head in the
problem**, so that they can notice the investigation has gone quiet, that nobody has updated support
for forty minutes, or that it is time to wake somebody else.

Three phrases do most of the work, and teams that use them sound alike:

- **"What is the status?"** from the IC, on a fixed rhythm, every ten to fifteen minutes.
- **"I am going to…, objections?"** from anybody about to change production, so that two changes
  never collide.
- **"Who owns this?"** for every action, so that *somebody should check the database* becomes
  *Carla is checking the database, report in ten minutes*.
