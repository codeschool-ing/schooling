---
title: When Kubernetes is more than the problem
version: 1
---

**A cluster is overkill when the decisions it automates are decisions nobody needed made.** The
loop from lesson 1 is valuable in proportion to how often the world drifts from what was written
down: copies crashing, machines failing, deploys happening, load changing. Where none of that
happens often, the loop has little to do and still has to be fed.

## What you take on with it

The bill for Kubernetes arrives in four parts, and only the first is money.

- **The control plane has to be kept up.** If it stops, running copies keep running, and nothing
  can change: no deploy, no replacement for a copy that dies, no scaling. Lesson 4 stops part of it
  on purpose to show exactly that.
- **It has to be upgraded.** The Kubernetes project releases three minor versions a year and
  supports each for about fourteen months, so a cluster that is left alone falls out of support
  inside a year and a half. Managed providers charge extra to keep an old version running, as
  lesson 6 shows.
- **There is a vocabulary to learn.** This course is 48 lessons long for a reason, and every person
  who touches the cluster needs some of it.
- **The machines themselves.** A highly available control plane is three machines before the first
  copy of the application runs, or a managed service with a fee per cluster per hour.

## Questions that decide it

None of these settles it alone, but together they usually do.

| question | points towards a simpler tool | points towards Kubernetes |
|---|---|---|
| how many services? | one to a handful | dozens, owned by different teams |
| how many machines? | one or two | many, and they come and go |
| how often do you deploy? | weekly or less | many times a day |
| does load change a lot? | it is steady | it swings, and capacity costs money |
| must it move between providers? | no, one cloud is fine | yes, or it must also run on your own machines |
| who will operate it? | nobody full time | a team, or a managed provider and a team |

**A useful rule is to take the least machinery that answers the questions you actually have.** One
service on one machine is Compose, from lesson 1. A few services on one cloud, with nobody to run a
cluster, is usually that cloud's own runner or a platform. Kubernetes earns its cost when many
teams deploy many services often, when the same files must run in several places, or when the
packaged software built around it (lesson 37 installs some) saves more work than the cluster
costs.

## And when the decision has been made for you

Often it has. A company already running Kubernetes will put the next service on it, because the
cluster's cost is already paid and one more set of objects is cheap. That is a sound reason, and
it is the situation most people learning this course will meet first. What this section asks is
that you can tell it apart from the other one: a new team, with one service, choosing a cluster
because it is what everybody uses.
