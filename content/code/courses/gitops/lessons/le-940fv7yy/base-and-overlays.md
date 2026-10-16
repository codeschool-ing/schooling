---
title: A base and two overlays
version: 1
---

**The base is what every environment has in common, and it says nothing about any of them.** No
namespace, no replica count worth keeping, no image tag, no message. In `fleet`, on a new branch,
the base is three files in `apps/bulletin/base/`. Save this as `apps/bulletin/base/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bulletin
  template:
    metadata:
      labels:
        app: bulletin
    spec:
      containers:
      - name: bulletin
        image: localhost:5001/bulletin
        envFrom:
        - configMapRef:
            name: bulletin
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
```

this as `apps/bulletin/base/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: bulletin
spec:
  type: NodePort
  selector:
    app: bulletin
  ports:
  - port: 80
    targetPort: 8080
```

and this as `apps/bulletin/base/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
```

The message no longer sits in the Deployment: it comes from a ConfigMap called `bulletin`, through
`envFrom`, and each environment generates its own. The next section says why that is better than
a value in the Deployment.

## Staging, as an overlay

An overlay lists the base as a resource and then says what is different. Save this as
`apps/bulletin/staging/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: staging
resources:
- namespace.yaml
- ../base
replicas:
- name: bulletin
  count: 3
images:
- name: localhost:5001/bulletin
  newTag: "1.1"
configMapGenerator:
- name: bulletin
  literals:
  - MESSAGE=Staging is updated by a webhook.
patches:
- target:
    kind: Service
    name: bulletin
  patch: |-
    - op: add
      path: /spec/ports/0/nodePort
      value: 30080
```

and its namespace as `apps/bulletin/staging/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
```

Every line of the overlay is something staging decides: its namespace, its replicas, its release,
its message and its port. **Reading the overlay is reading what makes staging staging**, which is
what the diff of two whole files tried and failed to show. Production's overlay is the same shape
with production's answers, plus one thing staging does not have, which the next section adds. The
old `bulletin.yaml` in each directory is deleted.

## Checking the result before anybody merges it

`kubectl kustomize` builds an overlay into plain manifests, exactly what Flux will apply, and
`kubectl diff` compares those with the live objects. Two flags make the comparison honest:
`--server-side` asks the API server to dry-run the apply, and `--field-manager=kustomize-controller`
makes it apply as Flux does, as the owner of the fields Flux set. Without them the diff shows what
*your* `kubectl apply` would change, which for a field Flux owns and you do not, like the old `env`,
is nothing:

```
ana@laptop:~/fleet$ git switch --quiet -c kustomize
ana@laptop:~/fleet$ find apps -type f | sort
apps/bulletin/base/deployment.yaml
apps/bulletin/base/kustomization.yaml
apps/bulletin/base/service.yaml
apps/bulletin/production/kustomization.yaml
apps/bulletin/production/namespace.yaml
apps/bulletin/staging/kustomization.yaml
apps/bulletin/staging/namespace.yaml
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | grep -A4 '^kind: ConfigMap'
kind: ConfigMap
metadata:
  name: bulletin-t55m2kmd94
  namespace: staging
---
ana@laptop:~/fleet$ kubectl diff --server-side --field-manager=kustomize-controller -k apps/bulletin/staging | grep '^[-+] '
-  generation: 5
-  labels:
-    kustomize.toolkit.fluxcd.io/name: staging
-    kustomize.toolkit.fluxcd.io/namespace: flux-system
+  generation: 6
-      - env:
-        - name: MESSAGE
-          value: Staging is updated by a webhook.
+      - envFrom:
+        - configMapRef:
+            name: bulletin-t55m2kmd94
+  MESSAGE: Staging is updated by a webhook.
+  creationTimestamp: "2026-10-10T06:24:30Z"
+  name: bulletin-t55m2kmd94
+  namespace: staging
+  uid: ce10691e-4d23-4b3e-9577-cb0a176e4420
-    kustomize.toolkit.fluxcd.io/name: staging
-    kustomize.toolkit.fluxcd.io/namespace: flux-system
-  labels:
-    kustomize.toolkit.fluxcd.io/name: staging
-    kustomize.toolkit.fluxcd.io/namespace: flux-system
```

Read it in three groups. The `kustomize.toolkit.fluxcd.io` labels are Flux's own: it adds them to
everything it applies, so they show as removed here and will be back after the merge. `generation`,
`creationTimestamp` and `uid` are the API server's bookkeeping for an object that changes or is
created. What is left is the change itself: the message arrives through a ConfigMap whose name ends
in a hash, instead of as an `env` entry, and that changes the pod template, so the pods will roll
once. **Nothing else changes**: no namespace, replica count, image or port appears in the diff. That
is the check worth making before a refactoring like this one is merged, because the pull request's
own diff shows only files deleted and files created.

## The check grows with the layout

Lesson 2's `validate.sh` handed `kubeconform` a directory of manifests. A directory of overlays is
not that: `kustomization.yaml` is not a Kubernetes object, and the objects only exist once the
overlay is built. So the check builds every directory under `apps/` that has a `kustomization.yaml`
and validates what comes out. Here is `~/setup/validate.sh`, rewritten:

```sh
#!/bin/sh
# The course's CI: build and check every overlay of one commit of fleet, and
# report the result to Gitea.
# Usage: sh validate.sh COMMIT
sha=$1 api=http://localhost:3000/api/v1/repos/ana/fleet
work=$(mktemp -d)
git clone --quiet http://localhost:3000/ana/fleet.git "$work/fleet"
git -C "$work/fleet" checkout --quiet "$sha"
state=success text="every overlay builds and validates"
for dir in "$work"/fleet/apps/*/*; do
  [ -f "$dir/kustomization.yaml" ] || continue
  name=$(basename "$(dirname "$dir")")/$(basename "$dir")
  if ! kubectl kustomize "$dir" > "$work/out.yaml"; then
    state=failure text="$name does not build"
  elif ! kubeconform -strict -summary -skip HelmRelease -kubernetes-version 1.37.0 "$work/out.yaml"; then
    state=failure text="$name does not validate"
  fi
done
curl -s -o /dev/null -H "Authorization: token $(cat ~/ci.token)" \
  -H 'Content-Type: application/json' \
  -d "{\"state\": \"$state\", \"context\": \"validate\", \"description\": \"$text\"}" \
  "$api/statuses/$sha"
echo "validate: $state"
rm -rf "$work"
```

The build goes to a file rather than a pipe, so that an overlay that fails to build fails the check
instead of handing `kubeconform` nothing. `-skip HelmRelease` is the one kind it cannot validate,
because its schema is Flux's and not Kubernetes', and that kind arrives at the end of this lesson.
Run against the pull request's head, it builds the base and both overlays:

```
ana@laptop:~/fleet$ git commit --quiet -m "bulletin: a base and two overlays"
ana@laptop:~/fleet$ git push --quiet -u origin kustomize 2>/dev/null
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 2 resources found in 1 file - Valid: 2, Invalid: 0, Errors: 0, Skipped: 0
Summary: 4 resources found in 1 file - Valid: 4, Invalid: 0, Errors: 0, Skipped: 0
Summary: 4 resources found in 1 file - Valid: 4, Invalid: 0, Errors: 0, Skipped: 0
validate: success
```
