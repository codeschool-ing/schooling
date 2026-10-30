---
title: What the Recommender proposes, and what it knows
version: 1
---

**Google's Recommender watches how resources are used and proposes changes: a smaller machine type, an idle
machine to stop, a disk nobody has attached, an address nobody uses.** Each recommendation comes with the evidence
window, the expected change in cost and a state you can mark as claimed, succeeded or dismissed. It is free, and it
is right more often than people's intuition about their own machines. It is also computed from the past and knows
nothing about next week. Nothing in this section ran: the Recommender needs a project with real usage. It is taught
from Google's documentation.

## The recommenders that matter for cost

| recommender | what it proposes |
|---|---|
| `google.compute.instance.MachineTypeRecommender` | a machine type that fits the observed CPU and memory |
| `google.compute.instance.IdleResourceRecommender` | stopping or deleting a machine with almost no activity |
| `google.compute.disk.IdleResourceRecommender` | deleting a persistent disk attached to nothing |
| `google.compute.address.IdleResourceRecommender` | releasing a static IP address in use by nothing |
| `google.compute.commitment.UsageCommitmentRecommender` | the commitment of lesson 21 |

Listing one kind, for the shop's zone:

```sh
gcloud recommender recommendations list \
  --project=planner-dev --location=southamerica-east1-a \
  --recommender=google.compute.instance.MachineTypeRecommender \
  --format='table(description, primaryImpact.costProjection.cost.units, stateInfo.state)'
```

Not run. Each line would read like "Save cost by changing machine type from e2-standard-8 to e2-standard-4", the
projected monthly change in cost (negative is a saving) and the state, `ACTIVE` for one nobody has acted on.

## What it observes, and what it cannot

A machine-type recommendation looks at **CPU and memory over the last eight days**, and memory only if the Ops Agent
is installed and reporting it; without the agent, the Recommender sizes on CPU alone and can propose a machine too
small to hold what is in memory. An idle-machine recommendation looks for very low CPU and network over a similar
window.

What none of them can see:

- **a monthly job**: the machine that is idle for 29 days and busy on the 1st;
- **a machine kept warm on purpose**, a standby that must be ready in seconds;
- **who owns it**, and whether they meant to keep it.

So a recommendation is the start of a question to the owner, never an action taken on its own. The next section
writes the rule out by hand, to see what a rule like the Recommender's decides and why.
