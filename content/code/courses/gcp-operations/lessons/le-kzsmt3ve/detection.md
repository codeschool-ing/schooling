---
title: From an alert to a declared incident
version: 1
---

**An incident is declared, not discovered.** An alert fires, a customer writes, a colleague notices a graph;
none of those is an incident yet. It becomes one when somebody says so, out loud, in the place the team
works, and takes the role of running it. Declaring early costs a message and five minutes of somebody's
attention. Declaring late costs the half hour in which three people investigated the same thing separately and
nobody told the customers. **This lesson is about people and process**, and there is little to run; the one
practical part is the timeline, built from lesson 10's log in the third section.

## Where incidents come from

Most incidents are noticed in one of four ways, and the order of this list is the order of preference:

1. **An alert on a symptom**: lesson 13's fast burn, lesson 8's uptime check.
2. **A person looking at a dashboard** for another reason.
3. **A customer** writing to support.
4. **The bill**, a week later (lesson 25).

Every incident noticed by the third or fourth way is a question for the postmortem: why did the alerts not
catch it? The shop's payment incident of lesson 10 is one of those, and the third section shows why.

## Severity, decided in a minute

| severity | what it means for the shop | who is involved |
|---|---|---|
| SEV1 | checkout is down or charging wrongly | everybody, now, and customers are told |
| SEV2 | checkout works for most, fails or is slow for some | the person on call and one more |
| SEV3 | something is degraded and nobody is blocked | the person on call, in working hours |

Pick the higher one when unsure. **Lowering a severity later is free; raising it later means the people who
should have been there from the start join a conversation already half an hour old.**

## The first five minutes

1. Say "I am declaring an incident, SEV2, payments retrying, I am incident commander" in the team's channel.
2. Open a document with the time and that sentence. It becomes the timeline.
3. Look at the SLO's budget (lesson 13): how fast is it burning, and since when?
4. Ask what changed: the last release (lesson 3's rollout history), the last Terraform apply (lesson 6's state
   versions), the last configuration change.
5. Decide whether the fastest way back is a rollback. Usually, if something changed in the last hour, it is.

The fifth step is the one teams skip, in favour of understanding the cause first. **Restoring the service comes
before understanding it**: a rollback (lesson 3) takes minutes and needs no diagnosis, and the cause can be
found afterwards, with the service working and nobody's checkout failing while it is.
