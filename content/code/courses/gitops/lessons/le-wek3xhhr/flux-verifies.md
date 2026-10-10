---
title: Flux refuses what nobody signed
version: 1
---

**Flux verifies the artefacts it pulls itself.** An `OCIRepository` takes a `verify` field naming the
provider, `cosign`, and a Secret holding the public keys; the source controller then checks the
signature of every revision before anything downstream sees it. The preview's chart is such an
artefact since lesson 7, so it is the one to protect. It is signed exactly like the image, by digest:

```
ana@laptop:~/signing$ CHART=$(curl -sI -H "Accept: application/vnd.oci.image.manifest.v1+json" localhost:5001/v2/charts/bulletin/manifests/0.1.0 | tr -d "\r" | awk "tolower(\$1) == \"docker-content-digest:\" { print \$2 }"); echo $CHART
sha256:98ccc0c8f616bc465570547bcc817f20ef82781b806664bc68b5f5aa048bc21d
ana@laptop:~/signing$ cosign sign --key cosign.key --signing-config offline.json -y localhost:5001/charts/bulletin@$CHART
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Signing artifact...
Pushing signature to: localhost:5001/charts/bulletin
```

The public key goes into the cluster the GitOps way, through the repository. It is not a secret, so
it can sit in Git as a file, and Kustomize makes the Secret out of it. This is
`apps/bulletin/preview/kustomization.yaml` after the change:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- namespace.yaml
- release.yaml
secretGenerator:
- name: cosign-pub
  namespace: preview
  files:
  - cosign.pub
generatorOptions:
  disableNameSuffixHash: true
```

`disableNameSuffixHash` keeps the name fixed, because the `OCIRepository` names it and is not one of
the objects Kustomize knows how to rewrite. And this is the `OCIRepository` in
`apps/bulletin/preview/release.yaml`, with the HelmRelease below it unchanged:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: bulletin-chart
  namespace: preview
spec:
  interval: 10m
  url: oci://registry:5000/charts/bulletin
  insecure: true
  ref:
    tag: 0.1.0
  verify:
    provider: cosign
    secretRef:
      name: cosign-pub
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: bulletin
  namespace: preview
spec:
  interval: 10m
  chartRef:
    kind: OCIRepository
    name: bulletin-chart
  values:
    message: A preview, installed by Helm.
```

```
ana@laptop:~/fleet$ git switch --quiet -c preview-verify
ana@laptop:~/fleet$ cp ~/signing/cosign.pub apps/bulletin/preview/
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+  namespace: preview
+  files:
+  - cosign.pub
+  disableNameSuffixHash: true
+  verify:
+    provider: cosign
+    secretRef:
+      name: cosign-pub
ana@laptop:~/fleet$ git add apps && git commit --quiet -m "preview: only a signed chart"
ana@laptop:~/fleet$ flux get sources oci -n preview
NAME          	REVISION             	SUSPENDED	READY	MESSAGE                                            
bulletin-chart	0.1.0@sha256:98ccc0c8	False    	True 	stored artifact for digest '0.1.0@sha256:98ccc0c8'	
ana@laptop:~/fleet$ kubectl -n preview get ocirepository bulletin-chart -o jsonpath='{.status.conditions[?(@.type=="SourceVerified")].message}'; echo
verified signature of revision 0.1.0@sha256:98ccc0c8f616bc465570547bcc817f20ef82781b806664bc68b5f5aa048bc21d
```

`SourceVerified` says it in words: Flux fetched the chart, found a signature beside its digest, and
checked it against the key in `cosign-pub` before handing the chart to the helm controller.

## A chart nobody signed

Somebody publishes `0.1.1` of the chart and proposes it for the preview, through a pull request like
every change. The chart is fine; it was simply never signed.

```
ana@laptop:~/fleet$ git switch --quiet -c preview-0.1.1
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-    tag: 0.1.0
+    tag: 0.1.1
ana@laptop:~/fleet$ git commit --quiet -am "preview: chart 0.1.1"
ana@laptop:~/fleet$ flux get sources oci -n preview
NAME          	REVISION             	SUSPENDED	READY	MESSAGE                                                                                                                                       
bulletin-chart	0.1.0@sha256:98ccc0c8	False    	False	failed to verify the signature using provider 'cosign': no matching signatures were found for 'registry:5000/charts/bulletin@sha256:1bb62840'	
ana@laptop:~/fleet$ helm list -n preview
NAME    	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART                      	APP VERSION
bulletin	preview  	2       	2026-10-10 19:42:55.090250565 +0000 UTC	deployed	bulletin-0.1.0+98ccc0c8f616	1.1        
```

Read the line carefully. `READY` is `False`, and the message names the digest of 0.1.1 and says no
signature matched. The `REVISION` column still says 0.1.0, because that is the last revision the
source accepted, and `helm list` agrees: **the preview keeps running the signed chart** while the
unsigned one is refused.

**This is the property the lesson is after**: the pull request passed review and CI, the merge
happened, and the cluster still refused, because the guarantee does not depend on anybody noticing.
The way out is to sign `0.1.1` or to go back to `0.1.0`, and either one is a decision with a name on
it.
