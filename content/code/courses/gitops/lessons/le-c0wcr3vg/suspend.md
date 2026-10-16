---
title: Suspending reconciliation, on the record
version: 1
---

**Lesson 2 ruled out pausing the agent and changing the cluster by hand, because nobody tracks the
difference afterwards.** Flux has a pause anyway, and it is worth seeing why it is not the same
thing: the pause is written into the object, where everybody can see it.

```
ana@laptop:~/fleet$ flux suspend kustomization staging
► suspending kustomization staging in flux-system namespace
✔ kustomization suspended
ana@laptop:~/fleet$ flux get kustomizations
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                              
flux-system	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
staging    	main@sha1:e22a01dd	True     	True 	Applied revision: main@sha1:e22a01dd	
```

`SUSPENDED True` is a field in the Kustomization's spec, not a process stopped on somebody's
laptop. Anybody who runs `flux get kustomizations` sees it, and so does any alert built on Flux's
status. While it is suspended, a merged change is fetched and not applied:

```
ana@laptop:~/fleet$ git switch --quiet -c follows-flux
ana@laptop:~/fleet$ git commit --quiet -am "staging: follows Flux"
ana@laptop:~/fleet$ flux reconcile source git flux-system
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:3bce7999e571acd755616e711af31028b3487c82
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:e22a01dd	True     	True 	Applied revision: main@sha1:e22a01dd	
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is ready for review.
token: none
```

The source controller fetched the new commit, `staging` stayed on the old one, and `curl` still
shows the old message. `flux resume` reconciles at once:

```
ana@laptop:~/fleet$ flux resume kustomization staging
► resuming kustomization staging in flux-system namespace
✔ kustomization resumed
◎ waiting for Kustomization reconciliation
✔ Kustomization staging reconciliation completed
✔ applied revision main@sha1:3bce7999e571acd755616e711af31028b3487c82
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging follows Flux.
token: none
```

**Use suspend for the minutes it takes to do something deliberate**, like a database migration
that must not be interrupted by an apply, and resume it as the last step of the same procedure. A
Kustomization suspended for a week is a cluster that has quietly stopped being GitOps.
