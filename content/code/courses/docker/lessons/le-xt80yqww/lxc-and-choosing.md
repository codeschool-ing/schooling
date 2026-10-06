---
title: LXC, and choosing
version: 1
---

**Everything in this course has been an application container: one program, its files, and walls
around it.** LXC, older than Docker, makes a different kind: a **system container**, a whole Linux
userland with its own init process, services and users, which behaves like a small virtual machine
while sharing the host's kernel like any container.

LXC was not run in the lab: a system container starts from a whole distribution image, from LXC's
own image server, and this course kept to OCI images. What it is for can be stated without running
it. **Incus**, the community continuation of LXD, manages
LXC containers and virtual machines with one command, and is how most people meet it now.

- **A system container** is where you would put a long-lived machine you log into, patch and keep:
  a build host, a lab, a service that expects systemd.
- **An application container** is what this course built: replaced, never patched, one process, the
  image as the unit of release.

## The tools side by side

| tool | daemon | default user | builds images | Compose files | typical use |
| --- | --- | --- | --- | --- | --- |
| Docker Engine | `dockerd` | root | yes, BuildKit | yes | development and single hosts |
| Podman | none | the user | yes, Buildah | yes, `podman compose` | rootless hosts, RHEL family |
| containerd + nerdctl | `containerd` | root | yes, with BuildKit | yes | the runtime under Kubernetes |
| LXC / Incus | `incusd` | root | no; system images | no | system containers, small VMs |

**All but the last run the same OCI images**, so the choice is about the machine and the team, not
about rebuilding anything. A laptop with Docker, a server with Podman, a cluster on containerd: one
image, built once by the pipeline of lesson 26, and named by its digest.

## Where the course leaves you

Lesson 1 started from a program that worked on one machine and not on another. Since then, `shelf` has
become an image built in stages, small and without root or shell, scanned, with its bill of materials
and its provenance. A pipeline publishes it with every check in front, and it runs under limits,
health checks and restart policies, alone or in a swarm. The next course in most tracks is
`kubernetes`, and its first lesson starts from the last section of lesson 27: what one machine cannot
do.
