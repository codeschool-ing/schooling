---
title: Incidents and problems
version: 1
---

The single distinction in ITIL that pays for itself most quickly is the one between an **incident** and a **problem**. Teams that do not make it end up either fixing the same failure every week or investigating while users wait.

## An incident is about restoring the service

ITIL defines an incident as **an unplanned interruption to a service, or a reduction in its quality**. Booking stops working in one clinic; the app takes twenty seconds to load the calendar; reminders stop being sent. The goal of incident management is to **restore normal service as quickly as possible**, and for that goal the cause is secondary. Restarting the reminder service, switching traffic to another server, or telling receptionists to book by phone for an hour are all good incident responses, even though none of them explains anything.

Each incident is recorded, classified and given a priority, which the next section computes. A **major incident** — one with enough impact to need its own procedure — gets a dedicated coordinator and communication to the affected users at set intervals.

## A problem is about the cause

A problem is **a cause, or potential cause, of one or more incidents**. When reminders stop being sent for the third Monday in a row, the three incidents have been resolved, and the problem is still there. **Problem management** investigates it: what changed on Mondays, which job runs then, why does it fail. It works on a different clock from incident management, and often with different people, because analysis cannot be done well while the service is down and everybody is watching.

When the cause is found but not yet fixed, the problem becomes a **known error**, recorded with its **workaround**: the steps that restore service when the incident happens again. A known error with a good workaround turns a two-hour incident into a five-minute one while the permanent fix waits for its turn in the backlog.

## Why the separation matters

Mixing the two produces both failures at once. A team that investigates during the incident keeps users waiting while it reads logs. A team that only restores never asks why, so the incident returns, and the help desk learns to apply the same restart every Monday without anybody recording that the restart is a workaround for an unexplained fault.

For an architect, the problem records are the most honest document the organisation has about the system. A list of known errors with workarounds is a list of design decisions that did not hold up in production, written by the people who pay for them.
