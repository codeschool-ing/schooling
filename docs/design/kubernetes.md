---
format: 5
course: kubernetes
---

# kubernetes

**Kubernetes: Orchestration in Production** · `co-mtqbwc3e` · 80 h declared · advanced · 48 lessons · `infra` · paid

## Reach

In **3 tracks** — `cloud-engineering`(6), `devops`(8), `devsecops`(11).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `docker` — images, containers and container networking.

**Leaves ready:** nothing. No course declares it in `requires`.

## Shape

| | |
|---|---|
| declared hours | 80 h |
| lessons | 48 |
| **hours per lesson** | **1.67** |
| section budget | ~192, about 4.0 a lesson |
| exercises | ~900, at the catalogue's density |


## Execution

| | |
|---|---|
| runtime | **a cluster.** Not a language runtime — a control plane, nodes and a scheduler |
| browser · database | no · no |
| exercises **blocked** | **0 as written**, and that is a statement about how the exercises would be phrased rather than about the course being fine |
| exercises that would **improve** | **nearly all of it.** `kubectl` against a live cluster is what this subject is; `ordering` and `cloze` teach the manifest and not the operation |
| diagrams to draw | ~55 — the most in the category: control plane, scheduling, service and ingress paths, rollout states |

## Ageing

**Moderate.** `kubectl` and the object model are stable; dashboards and managed-cluster consoles are not.

## Flags

**1 ·** **The only real hours flag in the category.** 48 lessons at the minimum shape of 4 sections is 192 sections, which is about 90 hours against 80 declared — the one course where the floor itself exceeds the budget. Everything else in `infra` fits.

**2 ·** **It is the course that redefines what the sandbox is being asked for.** A shell runs `git` and `docker`. A cluster is infrastructure with a cost per hour, and deciding to provide one is a different decision from adding a language.

**3 ·** **48 lessons and no dependents.** The largest course in the category serves only the three tracks that contain it, so its size is not owed to anybody downstream.
