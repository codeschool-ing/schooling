---
title: A chart installed by Flux
version: 1
---

**Flux installs a chart with Helm's own code, as a real Helm release**, so everything Helm knows
about a release, its history, its values and its rollback, is there for anybody with the `helm`
command. The chart comes from a source like everything else; here it is the `charts/bulletin`
directory of `fleet`, read through the same `GitRepository` Flux already has.

A third environment uses it, a preview that nobody reaches from outside. Save this as
`apps/bulletin/preview/release.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: bulletin
  namespace: preview
spec:
  interval: 10m
  chart:
    spec:
      chart: ./charts/bulletin
      sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
  values:
    message: A preview, installed by Helm.
```

this as `apps/bulletin/preview/namespace.yaml`, the same three lines as staging's with `preview`
in place of `staging`, and this as `apps/bulletin/preview/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- namespace.yaml
- release.yaml
```

and a third file in `clusters/lab/`, `clusters/lab/preview.yaml`, which is `staging.yaml` with
`preview` for `staging` in its name and its path. The HelmRelease overrides one value, the message,
and takes the rest from `values.yaml`.

```
ana@laptop:~/fleet$ git add charts apps/bulletin/preview clusters/lab/preview.yaml
ana@laptop:~/fleet$ cat clusters/lab/preview.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: preview
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/bulletin/preview
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: GitRepository
    name: flux-system
ana@laptop:~/fleet$ git commit --quiet -m "bulletin: a chart, and a preview installed from it"
ana@laptop:~/fleet$ flux get helmreleases -n preview
NAME    	REVISION	SUSPENDED	READY	MESSAGE                                                                          
bulletin	0.1.0   	False    	True 	Helm install succeeded for release preview/bulletin.v1 with chart bulletin@0.1.0	
ana@laptop:~/fleet$ helm list -n preview
NAME    	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
bulletin	preview  	1       	2026-10-10 06:25:09.524456214 +0000 UTC	deployed	bulletin-0.1.0	1.1        
ana@laptop:~/fleet$ helm history bulletin -n preview
REVISION	UPDATED                 	STATUS  	CHART         	APP VERSION	DESCRIPTION     
1       	Sat Oct 10 06:25:09 2026	deployed	bulletin-0.1.0	1.1        	Install complete
ana@laptop:~/fleet$ kubectl -n preview exec deploy/bulletin -- wget -qO- localhost:8080
bulletin 1.1
message: A preview, installed by Helm.
pod: bulletin-94d74b59f-jmsvg
token: none
```

The helm controller rendered the chart with those values and installed it. **`helm list` and
`helm history` see the release Flux made**, because it is an ordinary Helm release, stored where
Helm stores them, in a Secret in the release's namespace. The page answers from inside the pod,
since nothing maps a port of your machine to the preview.

Argo CD treats the same chart differently, as lesson 4's comparison said: it renders the templates
with the same values and applies the manifests, and `helm list` shows nothing. Both are reasonable;
what matters is knowing which one you run before reaching for `helm rollback` during an incident.
