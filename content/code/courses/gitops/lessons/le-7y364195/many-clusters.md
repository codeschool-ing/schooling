---
title: More than one cluster
version: 1
---

**This course runs one cluster with two namespaces**, which is enough to see every idea and cheap
enough for a laptop. Real organisations separate production from everything else by cluster, not
by namespace, and run several of each, per region or per team. The layout already has the place for
that: `clusters/` holds one directory per cluster, each with its own `flux-system` and its own files
pointing into `apps/`.

```
fleet/
  apps/
    bulletin/
      staging/
      production/
  clusters/
    staging-sp/
      flux-system/
      bulletin.yaml       path: ./apps/bulletin/staging
    production-sp/
      flux-system/
      bulletin.yaml       path: ./apps/bulletin/production
    production-us/
      flux-system/
      bulletin.yaml       path: ./apps/bulletin/production
```

Each cluster runs its own Flux, bootstrapped with its own `clusters/<name>` path, and pulls only
what its directory points at. **Adding a region is a new directory under `clusters/`**; the
application's configuration is not copied, because both production clusters point at the same
`apps/bulletin/production/`. When two of them need to differ, a per-cluster overlay holds just the
difference, and lesson 6 is about overlays.

Argo CD reaches the same shape from the other side: one Argo CD that manages several clusters, with
an ApplicationSet that generates one Application per cluster from a template and a list, or from
the clusters Argo CD knows about. Either way, **one place in Git per cluster, and one place per
application and environment**, is the layout that scales.

This layout was not run as three clusters for this course: the commands of lesson 1 build one, and a
second is the same `kind create cluster` with another name and another port mapping.
