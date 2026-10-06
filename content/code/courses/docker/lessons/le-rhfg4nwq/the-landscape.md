---
title: Swarm, Nomad, Kubernetes and PaaS
version: 1
---

**Every option in this section runs the same thing: an OCI image, ideally named by digest.** That is
what the course has been building towards. Where it runs is a separate decision, and changing it later
does not mean changing the image. None of the platforms below, other than Swarm, was run in the lab.

| | what you manage | good at | costs you |
| --- | --- | --- | --- |
| **Docker Swarm** | the machines and the swarm | small clusters, Compose files as they are | a smaller ecosystem; few new features |
| **HashiCorp Nomad** | the machines and the cluster | containers and non-container jobs together, simple to operate | fewer integrations than Kubernetes |
| **Kubernetes** | the cluster, or only the workloads on a managed one | almost everything, with the largest ecosystem | a lot of concepts before the first deploy |
| **A container PaaS** | the image and a few settings | a web service with no servers to look after | less control, and the provider's pricing and limits |

**Swarm** is what this lesson showed: built into Docker, quick to start, close to Compose. It is still
maintained, and it suits a few machines run by a small team; most new work has gone elsewhere.

**Nomad** schedules containers and also plain binaries and other workloads, from one small program.
It appeals to teams that want an orchestrator they can understand whole.

**Kubernetes** is the standard for running containers at scale, and it is a course of its own: the
`kubernetes` course starts, in lesson 1, from exactly the question this lesson asked, what Compose
does not solve, and compares these same alternatives in lesson 3. Its deployments do what `docker
service update` did, with the knobs its lesson 35 covers, and its probes, lesson 22, use the
`/health` endpoint `shelf` already has.

**A container PaaS takes the image and runs it**, scaling it with the traffic and often down to zero:
Google Cloud Run (lesson 8 of the `gcp-compute` course), AWS ECS with Fargate (lessons 8 and 9 of
`aws-compute`) and Azure Container Apps (lesson 8 of `azure-compute`). There is no node to patch and
no cluster to upgrade; what you give up is control over the machine, and what you accept is the
provider's model of requests, timeouts and pricing.

## How to choose

- **One service, one team, web traffic**: a PaaS, until something it does not do is needed.
- **A handful of machines you already run**: Compose per machine, or Swarm across them.
- **Many services, many teams, or a requirement a PaaS cannot meet**: Kubernetes, most often a managed
  one, and the `kubernetes` course.

Whatever the choice, the work of lessons 13 to 26 carries over unchanged: a small, non-root image,
scanned, with its SBOM and provenance, pushed by a pipeline and named by digest.
