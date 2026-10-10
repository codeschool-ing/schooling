---
title: The same flow, under pressure
version: 1
---

**The flow in this lesson takes minutes when everybody is at their desk. During an incident at
three in the morning it is the thing standing between the person on call and the fix**, and if it
is too slow, people go around it. Lesson 1 showed what going around it achieves: a manual change
that the agent undoes on its next pass. So the question is not whether to keep the flow during an
incident but how to make it fast enough.

## Make the normal path short

- **Small diffs.** A one-line change to `replicas` is reviewed in seconds. The habit of small pull
  requests in normal times is what makes a fast review possible in bad ones.
- **Somebody to approve.** An on-call rota with two people, or an agreement that any engineer may
  approve an emergency change, means the approval is a message away rather than a wait for morning.
- **Fast checks.** `kubeconform` on this repository takes well under a second. A check that takes
  ten minutes will be skipped the first time it matters.
- **A short interval, or a trigger.** The loop here waits fifteen seconds. Lesson 3's Argo CD and
  lesson 4's Flux can be told to look immediately, by a webhook from the Git server or a command.

## Break glass, on the record

Some situations really do need a change without a second person: the only person awake, the
review tool itself down. The answer is a **break-glass path that is narrow, rare and loud**, never a
quietly weakened rule:

- a dedicated account, not a person's everyday one, allowed to push to `main` (Gitea's protection has
  a push allow-list for exactly this: `enable_push_whitelist` with named users);
- its credentials kept where using them is itself an event: a sealed envelope, a vault that logs
  every read;
- and every use followed by a pull request after the fact that explains it, reviewed like any other.

The change still goes through Git, so the agent keeps it and the history records it. What the
emergency skips is the wait, never the record.

## What is never an option

**Pausing the agent and changing the cluster by hand.** It feels faster and it is the one choice
that leaves the cluster and the repository disagreeing with nobody tracking it. The next person to
resume the agent, perhaps days later, undoes the fix without knowing it was there.
