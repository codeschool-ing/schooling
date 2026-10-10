---
title: Automated sync, and pruning
version: 1
---

**A sync you have to type is a deploy tool, not a reconciler.** The Application gets a sync policy
that makes Argo CD apply every new commit on its own, delete what Git no longer describes, and undo
changes made behind its back. Here is `~/setup/bulletin-staging.yaml` with the policy added at the
end of `spec`:

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
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

`automated` alone syncs when Git changes. **`prune: true`** lets that sync delete objects that
disappeared from Git, and **`selfHeal: true`** makes it sync when the cluster changes too. Both are
off by default, deliberately: deleting things and overwriting people are the two actions a new
user of a tool should have to ask for.

@@capture policy

## A change, through Git only

The message changes the lesson 2 way: a branch, a commit, a pull request that the check and Bruno
approve, a merge. Then Argo CD has to notice:

@@capture change

Right after the merge, Argo CD still reports the old revision. **It looks at the repository on a
timer, every three minutes by default**, and nothing told it to look sooner. `--refresh` asks it to
look now; it found the new commit, and the automated policy synced it in the same pass. In a real
setup the Git server calls Argo CD's webhook on every push, which makes the wait a second or two
instead of minutes; lesson 4 sets one up for Flux.

## Pruning

Lesson 1's loop could not delete. Remove the Service from `staging/bulletin.yaml` through a pull
request, the same way:

@@capture prune

`pruned`. The Service carried Argo CD's tracking annotation, it was no longer in the rendered
manifests, so the controller deleted it. That is the whole mechanism, and it is also the danger:
**a file deleted by mistake in Git is an object deleted in the cluster on the next sync.** The
protection rule and the review of lesson 2 are what stand in the way of that mistake. The Service
comes back with a revert, through one more pull request.
