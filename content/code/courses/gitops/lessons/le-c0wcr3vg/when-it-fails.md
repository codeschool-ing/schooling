---
title: When Flux reports a failure
version: 1
---

Flux reports a failure as `READY False` on the object that failed, with the reason in the message,
and the chain from source to Kustomization tells you where to look first: **a source that is not
ready makes everything downstream stale, so read the chain from the left.** Each of these was
produced on purpose, and put right again.

## Credentials that stopped working

The Secret `fleet-auth` is replaced with a token that does not exist, and the source is told to
fetch:

```
ana@laptop:~/fleet$ kubectl -n flux-system create secret generic fleet-auth --from-literal=username=flux --from-literal=password=0123456789abcdef --dry-run=client -o yaml | kubectl apply -f -
Warning: resource secrets/fleet-auth is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
secret/fleet-auth configured
ana@laptop:~/fleet$ flux reconcile source git flux-system
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✗ context deadline exceeded
ana@laptop:~/fleet$ flux get sources git
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                                                                      
flux-system	main@sha1:218c0baa	False    	False	failed to checkout and determine revision: unable to list remote for 'http://gitea:3000/ana/fleet.git': authentication required: Failed to authenticate user	
           	                  	         	     	                                                                                                                                                            	
ana@laptop:~/fleet$ flux get kustomizations
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                              
flux-system	main@sha1:218c0baa	False    	True 	Applied revision: main@sha1:218c0baa	
staging    	main@sha1:218c0baa	False    	True 	Applied revision: main@sha1:218c0baa	
```

The `GitRepository` is not ready, and the message is the Git server's refusal. The Kustomizations
still say `True`, about the last artifact they applied, which is the trap: **nothing is being
deployed and nothing downstream looks broken.** `flux get sources git` is the first command after
any "my change did not arrive".

## A deployment that never becomes ready

With `wait: true`, a Kustomization is ready only when what it applied is. A pull request moves
staging to an image tag that does not exist:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-1.9
ana@laptop:~/fleet$ git commit --quiet -am "staging: bulletin 1.9"
ana@laptop:~/fleet$ flux reconcile kustomization staging --with-source
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ fetched revision main@sha1:419a987b0b377a51f0d172d951d2746cf749837d
► annotating Kustomization staging in flux-system namespace
✔ Kustomization annotated
◎ waiting for Kustomization reconciliation
✗ context deadline exceeded
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                           
staging	main@sha1:218c0baa	False    	False	health check failed after 2m0.020638498s: timeout waiting for: [Deployment/staging/bulletin status: 'InProgress']	
```

`flux reconcile` stopped waiting first, with `context deadline exceeded`. The Kustomization itself
says more: `health check failed` after the two minutes of `timeout`, naming the Deployment that did
not become ready, and `REVISION` still shows the last revision that succeeded, the one to return to.
Lesson 2 found the same failure by reading pods; here the agent reports it, on an object anybody can
query. The fix is the same: a revert, through a pull request.
