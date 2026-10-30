---
title: What Defender for Cloud is, and what is free
version: 1
---

**Defender for Cloud does two jobs that are worth keeping apart.** One is **posture**: it reads how your
resources are configured and compares them with a standard, recommending changes, before anything has
happened. The other is **workload protection**: it watches resources while they run and raises **alerts**
when something looks like an attack. The first is about doors left open; the second is about somebody
walking through one.

**Foundational CSPM**, the posture half at its basic level, is on for every subscription and costs
nothing: it assesses resources against the **Microsoft cloud security benchmark**, produces
recommendations and computes the **secure score**. Everything else is a paid plan, billed per resource
protected, and turned on per subscription and per resource type:

| plan | what it adds |
|---|---|
| **Defender CSPM** | attack path analysis, a security graph you can query, agentless scanning of VMs and containers |
| Defender for Servers | threat detection and vulnerability assessment on VMs |
| Defender for App Service, SQL, Storage | alerts on suspicious use of each service |
| Defender for Key Vault | alerts on unusual access to secrets and keys |
| Defender for Containers | posture and runtime protection for AKS and registries |

This course has no subscription, so **none of Defender was run**: no recommendation, score or alert in
this lesson came from Defender, and the examples are written by the course and say so. What can be
practised without it is the reasoning: how a score is computed, and which recommendation goes first.

Turning on every plan everywhere is the easy decision and an expensive one. The shop turns on Defender for
the services that hold its data and face the internet, App Service, SQL and Key Vault, in production
only, and leaves development on the free tier; lesson 22 has the habit of pricing such a decision before
making it.
