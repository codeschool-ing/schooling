---
title: The blameless postmortem
version: 1
---

A postmortem is a document written after the incident, and its purpose is the next incident: **what in
the system allowed this to happen, and what will make it less likely or less costly**. It is
**blameless** by rule, and the rule is not politeness. A review that finds "Carla deployed a bad change"
has found the last step, and the system that let a bad change reach every customer is still there for
the next person. People who expect blame stop telling the whole story, and the review loses exactly the
details that would explain the incident.

## The questions, in order

1. **Impact**: who was affected, how, for how long, and how much of the error budget it spent (lesson 12).
2. **Timeline**: the previous section's, with the people's decisions added.
3. **Detection**: how was it noticed, and how long did that take? Could an alert have noticed sooner?
4. **Response**: what worked, what slowed the team down: a missing runbook, a permission nobody had, a
   dashboard that lied.
5. **Contributing factors**: plural. Incidents rarely have one cause, and "root cause" invites the search
   to stop at the first one found.
6. **Actions**: each with an owner and a date, each changing the system rather than asking people to be
   more careful.

## Actions that change the system

"Be more careful when deploying" is not an action: nobody can be assigned it and nobody can tell when it
is done. The actions worth writing change something that persists:

| contributing factor | a weak action | an action that changes the system |
|---|---|---|
| a bad release reached all customers | test more carefully | canary with an alarm on the new version only (lesson 3) |
| the alarm went quiet when the service died | watch the dashboard | treat missing data as breaching (lesson 10) |
| the state file was deleted by hand | be careful in the console | a bucket policy refusing the delete (lesson 7) |
| a customer noticed first | monitor better | a burn-rate alert on checkout (lesson 12) |

Each right-hand cell is a change somebody can make, review and finish, and each one came from an earlier
lesson of this course, which is not a coincidence: **operations is mostly the accumulated actions of
earlier postmortems**.

## The meeting and the document

The review meeting walks the timeline with everybody who took part, within a few days while memory is
fresh, and its facilitator is somebody not involved. The document is shared widely, because the
contributing factors of one team's incident are usually present in another team's service. And the
action list is tracked to its end: **a postmortem whose actions are never done is a description of the
next incident**.
