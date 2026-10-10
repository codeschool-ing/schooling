---
title: A bootstrap that goes through review
version: 1
---

**`flux bootstrap` is the usual way in**: one command that installs Flux, commits Flux's own
manifests into the repository and points Flux at them, so that from then on Flux upgrades and
repairs itself from Git. It does it by pushing to `main`. On `fleet`, nobody pushes to `main`,
bootstrap included, and that is the rule working. So this section does by hand the three things
`flux bootstrap` does, and the commit goes through a pull request like everything else.

## The manifests, in the repository

Flux's components are one file that `flux install --export` writes. Two more files say what Flux
should read. In `~/fleet`, on a new branch:

```sh
mkdir -p clusters/lab/flux-system
flux install --export > clusters/lab/flux-system/gotk-components.yaml
```

Save this as `clusters/lab/flux-system/gotk-sync.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m
  url: http://gitea:3000/ana/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-auth
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 10m
  path: ./clusters/lab
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

and this as `clusters/lab/flux-system/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
```

The `GitRepository` fetches `fleet` every minute, with the credentials in a Secret called
`fleet-auth` that this section creates and that never goes into Git. The `Kustomization` called
`flux-system` applies everything under `clusters/lab` every ten minutes, **which includes Flux's own
manifests**: from now on, upgrading Flux is a pull request that changes `gotk-components.yaml`.

`clusters/lab/` is the directory for this cluster. Anything else this cluster should run gets a
file there, and the first one is staging. Save this as `clusters/lab/staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./staging
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: GitRepository
    name: flux-system
```

`wait: true` makes Flux wait for what it applied to become ready, up to `timeout`, before calling
the Kustomization ready: lesson 3's sync status and health, folded into one answer.

```
ana@laptop:~/fleet$ git switch --quiet -c flux
ana@laptop:~/fleet$ mkdir -p clusters/lab/flux-system
ana@laptop:~/fleet$ flux install --export > clusters/lab/flux-system/gotk-components.yaml
ana@laptop:~/fleet$ git rm -r --quiet argocd
ana@laptop:~/fleet$ git add clusters
ana@laptop:~/fleet$ git status --short
D  argocd/bulletin-staging.yaml
D  argocd/project-bulletin.yaml
A  clusters/lab/flux-system/gotk-components.yaml
A  clusters/lab/flux-system/gotk-sync.yaml
A  clusters/lab/flux-system/kustomization.yaml
A  clusters/lab/staging.yaml
ana@laptop:~/fleet$ wc -l clusters/lab/flux-system/gotk-components.yaml
6092 clusters/lab/flux-system/gotk-components.yaml
ana@laptop:~/fleet$ git commit --quiet -m "flux: bootstrap the lab cluster; argocd retired"
```

`git rm -r argocd` is in the same pull request, as the last section said. The diff is large because
`gotk-components.yaml` is: every resource type and controller of Flux, 6092 lines, written by a
program and pinned to one release.

## The three steps, by hand

After the merge, the cluster gets Flux's components, the credentials, and the pointer to Git, in
that order:

```
ana@laptop:~/fleet$ kubectl apply --server-side -f clusters/lab/flux-system/gotk-components.yaml | tail -n 2
service/webhook-receiver serverside-applied
deployment.apps/notification-controller serverside-applied
ana@laptop:~/fleet$ kubectl -n flux-system wait --for=condition=Available deployment --all --timeout=180s
deployment.apps/helm-controller condition met
deployment.apps/kustomize-controller condition met
deployment.apps/notification-controller condition met
deployment.apps/source-controller condition met
ana@laptop:~/fleet$ flux create secret git fleet-auth --url=http://gitea:3000/ana/fleet.git --username=flux --password="$(cat ~/flux.token)"
► git secret 'fleet-auth' created in 'flux-system' namespace
ana@laptop:~/fleet$ kubectl apply -f clusters/lab/flux-system/gotk-sync.yaml
gitrepository.source.toolkit.fluxcd.io/flux-system created
kustomization.kustomize.toolkit.fluxcd.io/flux-system created
ana@laptop:~/fleet$ flux get sources git
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                                           
flux-system	main@sha1:e22a01dd	False    	True 	stored artifact for revision 'main@sha1:e22a01dd'	
ana@laptop:~/fleet$ flux get kustomizations
NAME       	REVISION          	SUSPENDED	READY	MESSAGE                              
flux-system	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
staging    	main@sha1:e22a01dd	False    	True 	Applied revision: main@sha1:e22a01dd	
```

From the third command on, the cluster is Flux's. It fetched `main`, applied `clusters/lab`, which
created the `staging` Kustomization, which applied `staging/`. The objects lesson 3 left were
adopted without being recreated, and both Kustomizations report the commit they applied.
