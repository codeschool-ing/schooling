---
title: From controller to operator
version: 1
---

**An operator is a controller that encodes how to run one particular piece of software**, written by
people who know it well. The Backup controller knows one thing, a schedule. A PostgreSQL operator, such
as CloudNativePG from lesson 28, knows how to create a primary and replicas, how to promote a replica
when the primary dies, how to archive the write-ahead log to a bucket, and how to upgrade between
major versions in the right order. Each of those is a reconcile loop over objects like `Cluster` and
`Backup`, and each replaces a page of a runbook that a person used to follow at three in the
morning.

| | a controller | an operator |
|---|---|---|
| watches | any kind, built in or custom | the custom kinds of one application |
| knows | how to make the objects match | how to run that application: failover, backup, upgrade |
| examples | the Deployment, Job and node controllers | CloudNativePG, Strimzi for Kafka, cert-manager |
| written by | Kubernetes, or you | the application's experts, usually |

Before writing one, it is worth asking whether one exists: for widely used software, an operator
somebody else maintains is almost always better than a new one, and the questions to ask of it are the
ones from this lesson. What does it reconcile, what does it do when it cannot reach the API, and what
does it delete when its object goes away.

**An operator runs with broad permissions**, often across namespaces, so installing one is a decision
about trust as much as about convenience, in the same way lesson 37 said of a chart. Its RBAC is
worth reading before it runs.
