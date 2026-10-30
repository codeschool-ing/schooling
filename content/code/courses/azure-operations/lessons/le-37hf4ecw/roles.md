---
title: Declaring it, the roles, and the messages that go out
version: 1
---

**An incident starts when somebody declares it**, not when the first error happens. Declaring is a
small act with large effects: it opens a channel, assigns roles and starts a clock, and it tells everybody
else to stop changing things in that system. The shop declares on any page that a person confirms, and
gives every incident a **severity**:

| severity | what it means for the shop |
|---|---|
| SEV1 | the shop cannot take orders at all |
| SEV2 | some customers cannot complete a checkout |
| SEV3 | degraded, with a workaround; no lost sales |

Thursday was a SEV2. Three roles go to three different people as soon as there are three people:

- **the incident commander** coordinates and decides. Not the person typing commands: the one keeping the
  list of what has been tried, what is being tried, and who is doing it;
- **operations**, one or more people investigating and changing things, each change announced in the
  channel before it is made;
- **communications**, who writes to customers and to the rest of the company, on a schedule, so that
  operations is never interrupted to ask for an update.

On Thursday, Carla, on call, was commander and operations, and Dani took communications. With two people
that is the right split: the person who talks to customers should not be the one reading query results.

## The message

A status update has four parts and no guesses: **what customers see, since when, what is being done, and
when the next update comes.** Dani's first one, seven minutes after the declaration:

> Some customers cannot complete checkout. Since 14:05. We are investigating. Next update by 14:45.

It says nothing about SQL, nothing about cause, and promises nothing but the next update, because at
14:29 nobody knew the cause, and a guess published to customers is a guess that has to be retracted in
public. The internal update says more, the external one says less, and both say when the next one comes.
