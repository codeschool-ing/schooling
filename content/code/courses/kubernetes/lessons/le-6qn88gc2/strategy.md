---
title: Making several clusters act as one
version: 1
---

Sooner or later the clusters have to act together: the same application in two regions, a failover
when one goes down. There was once a project for doing this inside Kubernetes itself. **KubeFed**
ran a control plane above the clusters and pushed "federated" objects down into each. It was archived
in 2023, and what replaced it is less ambitious and works better: each concern is solved by the tool
that already owns it.

| Concern | What is used now |
| --- | --- |
| The same objects in every cluster | GitOps (lesson 39): one repository, one agent per cluster, or Argo CD's ApplicationSet generating an application per cluster |
| Sending users to the nearest healthy cluster | DNS or a global load balancer in front of the clusters, outside Kubernetes |
| A Service reachable from another cluster | The Multi-Cluster Services API (`ServiceExport`, `ServiceImport`), implemented by some providers and network plugins |
| Creating and upgrading the clusters themselves | The provider's tooling or Terraform, or Cluster API, which describes clusters as objects in a management cluster |

The first row is the one almost everybody needs, and it is the loop of lesson 39 run more than once.
**The repository becomes the place where "every cluster" is defined**, and a cluster that drifts is
corrected the same way a Deployment is.

## Two regions

The question that decides a region strategy is not about Kubernetes. **It is where the data lives.**
Stateless pods can run in both regions at once; a database cannot be written in two places without a
design built for it, as lesson 28 argued.

- **Active-passive.** One region serves; the other has the same applications deployed, scaled down or
  idle, and a copy of the data that trails behind. Failing over means promoting the copy and moving the
  traffic, and the data written in the last seconds before the failure can be lost. It is cheaper and
  simpler, and it is where most teams start.
- **Active-active.** Both regions serve at once, so there is no failover to rehearse, only capacity to
  lose. Every write has to be accepted somewhere both regions agree on, and that is a database choice
  first and a cluster layout second.

Either way, a failover that has never been practised is a hope. The test that matters is turning a
region off on purpose, on a quiet day, and counting what broke.
