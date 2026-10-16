---
title: The layout, by application and environment
version: 1
---

**`fleet` has grown by accretion**: `staging/` at the top from lesson 1, `clusters/lab/` from lesson
4. This section gives it the shape the rest of the course keeps:

```
fleet/
  apps/bulletin/staging/       what bulletin is in staging
  apps/bulletin/production/    what bulletin is in production (the next section)
  clusters/lab/                what this cluster runs: Flux itself, and one file per environment
```

`apps/` answers "what does this application need, per environment". `clusters/` answers "what does
this cluster run", and each file in it points at a directory under `apps/`. A second application is a
second directory under `apps/`; a second cluster is a second directory under `clusters/`.

## Moving staging

The move is two changes in one pull request: `git mv` the directory, and point the staging
Kustomization at its new path. One thing outside `fleet` knows the old path too: lesson 2's
`validate.sh` checks `$work/staging`, which is about to stop existing. Point it at `apps/` first,
so it checks every application and every environment from now on:

```sh
sed -i 's#"$work/staging"#"$work/apps"#' ~/setup/validate.sh
```

```
ana@laptop:~/fleet$ git switch --quiet -c layout
ana@laptop:~/fleet$ mkdir -p apps/bulletin
ana@laptop:~/fleet$ git mv staging apps/bulletin/staging
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  path: ./staging
+  path: ./apps/bulletin/staging
ana@laptop:~/fleet$ git status --short
R  staging/bulletin.yaml -> apps/bulletin/staging/bulletin.yaml
 M clusters/lab/staging.yaml
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-6b88476dc4-7pscf   1/1     Running   0          35s
bulletin-6b88476dc4-q9km6   1/1     Running   0          46s
bulletin-6b88476dc4-tjrjf   1/1     Running   0          34s
ana@laptop:~/fleet$ git commit --quiet -am "fleet: apps/bulletin/staging"
```

After the merge, Flux applied the same objects from their new path:

```
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:ee8f6633	False    	True 	Applied revision: main@sha1:ee8f6633	
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-6b88476dc4-7pscf   1/1     Running   0          50s
bulletin-6b88476dc4-q9km6   1/1     Running   0          61s
bulletin-6b88476dc4-tjrjf   1/1     Running   0          49s
```

The pods have the same names as in the listing taken before the commit: **nothing was
recreated.** The objects are the same
objects, owned by the same Kustomization, read from a different directory. A move in Git is not a
delete in the cluster, as long as the same Kustomization keeps owning what moved. Had the move
gone to a directory that a *different* Kustomization reads, the first one would have pruned the
objects and the second created them again, which for a Deployment means new pods and for a
PersistentVolumeClaim can mean an empty disk.
