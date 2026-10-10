---
title: The first Application
version: 1
---

**An Application says: this path of this repository belongs in this namespace.** Save this one as
`~/setup/bulletin-staging.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bulletin-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea:3000/ana/fleet.git
    targetRevision: main
    path: staging
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
```

`source` is the Git half: the repository, the branch to follow and the directory. `destination` is
the cluster half: `https://kubernetes.default.svc` is the cluster Argo CD itself runs in, and
`staging` the namespace for objects that do not name one. `project: default` is a group of rules
that allows everything; the end of this lesson writes a stricter one.

If lesson 2's `reconcile.sh` is still running in a terminal, **stop it with `Ctrl+C` first**. Two
agents applying the same objects is the "two truths" problem of lesson 2, even when they happen to
read the same truth.

@@capture create

## Out of sync, and healthy

Argo CD read the repository at `main`, rendered `staging/`, compared the three objects with the
cluster and reported two things about each. It says **`OutOfSync`**, though nothing in the
repository differs from what lesson 2 deployed. The diff says why:

@@capture diff

The only difference is an annotation Argo CD wants on every object it manages,
`argocd.argoproj.io/tracking-id`, naming the Application that owns it. **That label is how Argo CD
knows what is its own.** It is exactly what lesson 1's loop lacked: when an object disappears from
Git, Argo CD can find the objects that still carry its tracking id and delete them. Nothing has been
synced yet, so no object carries it.

And it says **`Healthy`**, at the same time, about the same objects. The next section is about why
those are two different questions.
