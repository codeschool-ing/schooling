---
title: How Flux reconciles, and how it differs
version: 1
---

**Flux and Argo CD agree on what to do and disagree on when.** Argo CD watches the objects it
manages and reacts to a change in seconds, as lesson 3 showed. Flux's kustomize controller applies
on its interval and does not watch: a change made by hand lasts until the next reconciliation.

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=6
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   6/6     6            6           2m48s
ana@laptop:~/fleet$ flux reconcile kustomization staging --with-source
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:e22a01dd6bc44257bd1269ca7f2852ddb77ce143
► annotating Kustomization staging in flux-system namespace
✔ Kustomization annotated
◎ waiting for Kustomization reconciliation
✔ applied revision main@sha1:e22a01dd6bc44257bd1269ca7f2852ddb77ce143
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     3            3           2m53s
```

The scale to six was still there after twenty seconds, and the Kustomization had not noticed,
because it was not looking. `flux reconcile` asks for a reconciliation now, and it put the
deployment back to three. With `interval: 10m`, the longest a manual change survives is ten
minutes; a shorter interval costs one dry run and apply of the path per interval, which for a
directory of three objects is nothing and for a thousand objects is not.

`--with-source` makes the source controller fetch first, so the reconciliation uses the newest
commit rather than the last artifact. It is the command to type after a merge when you do not want
to wait for the next fetch; the webhook at the end of this lesson removes the need for it.

## What Flux reports

Everything Flux knows about a Kustomization is in its status, and `flux get` prints the summary:

```
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
ana@laptop:~/fleet$ kubectl -n flux-system get kustomization staging -o jsonpath='{.status.lastAppliedRevision}'; echo
main@sha1:e22a01dd6bc44257bd1269ca7f2852ddb77ce143
```

`READY True` with the revision applied, `main@sha1:` and the commit, is the same pair of facts Argo
CD reported: which commit, and whether it worked. Because of `wait: true`, ready already means that
the deployment's pods became available, not only that the apply succeeded.

## Leaving a field alone

Flux's version of lesson 3's `ignoreDifferences` is coarser: an annotation on the object in Git,
`kustomize.toolkit.fluxcd.io/ssa: IfNotPresent`, makes Flux create the object if it is missing and
never touch it again. For a field that an autoscaler owns, the cleaner answer from lesson 2 still
holds and works the same with both tools: **leave the field out of the manifest**, and nothing
fights over it.
