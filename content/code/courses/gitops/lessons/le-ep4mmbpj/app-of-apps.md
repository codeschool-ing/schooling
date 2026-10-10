---
title: Applications in Git, too
version: 1
---

**The Application lives in `~/setup` on your machine, applied by hand**, which is exactly the
situation this course has been removing for everything else. If your laptop disappears, nobody else
knows how staging is wired to the repository. The fix is the obvious one: put the Application in
`fleet` and let Argo CD apply it.

That needs one Application applied by hand, once, whose job is to apply the others. It is called
the **app of apps**, or the root. Save this as `~/setup/root.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea:3000/ana/fleet.git
    targetRevision: main
    path: argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

It points at a directory `argocd/` in `fleet`, and every Application manifest in that directory is
one of its objects. Move the staging Application there, through a pull request, and apply the root:

@@capture root

Both are `Synced`. The root found `argocd/bulletin-staging.yaml` in Git, compared it with the
Application that already existed, and adopted it. From now on, **adding an application to the
cluster is a pull request that adds a file to `argocd/`**, and removing one is a pull request that
deletes it, with the prune of the last section doing the rest.

@@figure root

The one thing left outside Git is `~/setup/root.yaml` and the Argo CD installation itself. That is the
bootstrap, and every GitOps setup has one: something has to exist before the agent can read the
repository. Keeping it to two files you can apply in a minute is the goal. Lesson 5 comes back to
this, with Flux, whose bootstrap commits itself into the repository.
