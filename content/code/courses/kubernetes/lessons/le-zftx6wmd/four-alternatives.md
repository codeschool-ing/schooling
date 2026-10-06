---
title: Four other answers to the same problem
version: 1
---

**Kubernetes is not the only orchestrator, and for many teams it is not the best one.** Every
tool in this section answers the problems lesson 1 measured — copies on several machines, one
address in front of them, updates without a gap — and each draws the line of what you run yourself
in a different place. That line is the thing to compare, more than any feature list.

## Swarm mode: Docker, spread over machines

Swarm mode is built into the Docker Engine. `docker swarm init` turns one machine into a manager,
`docker swarm join` adds others, and a `compose.yaml` becomes a running application with
`docker stack deploy`. It keeps a replica count, spreads copies over the machines, publishes a port
on every machine through what it calls the routing mesh, and updates one copy at a time, with
`--update-order start-first` reversing the order that cost lesson 1 its twelve requests.

Its strength is that there is almost nothing new to learn after the `docker` course: the file is the
same file. Its weakness is the size of what surrounds it. There is no equivalent of the thousands of
packaged applications, operators and integrations written for Kubernetes, and most hosting providers
offer no managed Swarm at all.

*This course does not show Swarm running.* The laptop it was recorded on turned Swarm mode on, but
the routing mesh never answered on the published port, so there was no honest transcript to show.

## Nomad: one binary, and not only containers

HashiCorp's Nomad is a scheduler distributed as a single binary that runs as either a server or a
client. Its jobs can be Docker containers, but also a plain executable, a Java program or a virtual
machine, which matters to a company that still has a lot of software that was never put in an
image. It leaves service discovery and secrets to its siblings, Consul and Vault, so a full setup is
three products rather than one.

**Its licence changed in 2023** from an open-source one to the Business Source License, which
allows most internal use and restricts offering it as a competing service. For a team choosing a
foundation for the next ten years, who owns the code is part of the decision.

## ECS: the cloud provider's own orchestrator

Amazon ECS runs containers on AWS with a control plane AWS operates and does not charge for. You
describe a *task* (one or more containers) and a *service* (how many tasks, behind which load
balancer), and they run either on virtual machines you manage or on Fargate, where there is no
machine for you to see. Google's Cloud Run and Azure Container Apps are close relatives on their
own clouds.

The price of that convenience is that the description only means something on that provider. An ECS
task definition is not a file any other cloud reads, and moving means rewriting it.

## A platform: hand over an image and stop there

At the far end are platforms — Heroku, Fly.io, Cloud Run in its simplest use, and many others —
where you give an image or even source code, say how much memory it needs, and receive an address.
Scaling, certificates and the machines are theirs. You give up control of the network, of where
things run, and of anything the platform did not think of, and you pay per use at a rate higher
than the machines would cost you.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A chart with two axes. Across, how much you operate yourself, from a lot on the left to almost nothing on the right. Up, how easily the same description moves elsewhere. Your own Kubernetes, Swarm mode and Nomad sit at the top left. Managed Kubernetes sits at the top, further right. ECS, Cloud Run and Container Apps sit lower and to the right, and a platform sits at the bottom right.\"><defs><marker id=\"alt-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M80 260 L690 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#alt-ah-wire)\"></path><path d=\"M80 260 L80 20\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#alt-ah-wire)\"></path><text x=\"690\" y=\"282\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">you operate less</text><text x=\"92\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the files move more easily</text><rect x=\"110\" y=\"46\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kubernetes, your own</text><rect x=\"110\" y=\"96\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Swarm mode, Nomad</text><rect x=\"350\" y=\"66\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kubernetes, managed</text><rect x=\"400\" y=\"150\" width=\"230\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ECS, Cloud Run, Container Apps</text><rect x=\"500\" y=\"206\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a platform</text></svg>", "caption": "Most tools trade one axis for the other. Kubernetes is the one that appears twice near the top: run yourself, or run by a provider, with the same files."}
```

| | who runs the control plane | what you describe | where it runs |
|---|---|---|---|
| Kubernetes, your own | you | objects in YAML (lesson 2) | anywhere, the same files |
| Kubernetes, managed (lesson 6) | the provider | the same objects | any provider that offers it |
| Swarm mode | you | a `compose.yaml` | wherever Docker runs |
| Nomad | you | a job file in HCL | anywhere, plus non-container work |
| ECS, Cloud Run, Container Apps | the provider | that provider's format | that provider only |
| a platform | the provider | an image, a size, a domain | that platform only |

**Read the table for the pattern rather than the cells.** Going down it, you operate less and you
can move less. Kubernetes is unusual in sitting at both ends: you can run it yourself on any
machines, or have any of the large providers run its control plane, and the files you write are the
same either way.
