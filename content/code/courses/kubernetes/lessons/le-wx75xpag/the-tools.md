---
title: Argo CD and Flux
version: 1
---

Everything in the previous two sections was a person running two commands. **Argo CD and Flux are
those two commands running inside the cluster, forever**: each watches one or more repositories,
renders what is there (plain manifests, Kustomize or Helm), compares it with the cluster, and applies
the difference. Neither was installed in this lab, so what follows describes them and was not run.

::: track devops
The `gitops` course, which comes later in your track, installs and runs both: Argo CD in its lesson 3
and Flux in its lesson 4. What follows is only enough to recognise them.
:::

::: track *
The `gitops` course installs and runs both, Argo CD in its lesson 3 and Flux in its lesson 4. What
follows is only enough to recognise them.
:::

| | Argo CD | Flux |
|---|---|---|
| the unit it manages | an `Application`: a repository path and a destination cluster and namespace | a `GitRepository` source plus a `Kustomization` or `HelmRelease` that applies it |
| how you see it | a web interface showing every application's sync and health | `kubectl` and the `flux` command line; interfaces are add-ons |
| shape | one set of components with a UI and its own users | a set of small controllers, one per job |
| shared by both | pulls from git, compares, applies, reports drift, can prune what was removed | |

**Both pull; nothing pushes.** The pipeline that builds an image does not hold credentials to the
cluster: it commits a new tag to the repository, and the tool inside the cluster picks it up. That
removes the most powerful credential from the most exposed system, the CI server.

The by-hand loop of this lesson had one gap a tool closes: `kubectl apply` never deletes what was
removed from the repository, as lesson 38's leftover ConfigMap showed. Both tools can prune, deleting
objects that the repository no longer contains, and both make that a setting, because deleting is the
one action that cannot be undone by the next sync.
