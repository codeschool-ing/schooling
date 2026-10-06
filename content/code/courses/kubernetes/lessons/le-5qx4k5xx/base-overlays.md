---
title: A base and the differences
version: 1
---

**The base is the shop as every environment runs it**, written as ordinary manifests, plus a
`kustomization.yaml` that lists them:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: shop:1.0
        envFrom:
        - configMapRef:
            name: shop-settings
```

```yaml
resources:
- deployment.yaml
- service.yaml
configMapGenerator:
- name: shop-settings
  literals:
  - GREETING=hello
```

The `configMapGenerator` writes the ConfigMap the Deployment reads its environment from, so the
setting lives in one line instead of a file of its own.

## Two overlays

An overlay names the base as a resource and says what to change. Staging keeps one replica and its own
greeting, and gets a suffix on every name:

```yaml
resources:
- ../../base
namespace: staging
nameSuffix: -staging
labels:
- pairs:
    env: staging
configMapGenerator:
- name: shop-settings
  behavior: merge
  literals:
  - GREETING=staging
```

Production keeps the names, takes the newer image, and patches the replica count:

```yaml
resources:
- ../../base
namespace: production
labels:
- pairs:
    env: production
images:
- name: shop
  newTag: "1.1"
patches:
- path: replicas.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
```

**The patch is a fragment of the object it changes**: the same kind and name, and only the fields to
replace. Kustomize finds the matching object in the base and merges the two.

```
ana@laptop:~/shop$ find deploy -type f | sort
deploy/base/deployment.yaml
deploy/base/kustomization.yaml
deploy/base/service.yaml
deploy/overlays/production/kustomization.yaml
deploy/overlays/production/replicas.yaml
deploy/overlays/staging/kustomization.yaml
```

## Building

`kubectl kustomize` prints what an overlay produces, without touching the cluster:

```
ana@laptop:~/shop$ kubectl kustomize deploy/overlays/production | grep -E "^kind|^  name|namespace:|replicas|image:|env:"
kind: ConfigMap
    env: production
  name: shop-settings-f655md8fbd
  namespace: production
kind: Service
    env: production
  name: shop
  namespace: production
kind: Deployment
    env: production
  name: shop
  namespace: production
  replicas: 3
```

Every object went to `production`, got the `env` label, and the Deployment got three replicas and
`shop:1.1`. **The ConfigMap's name gained a hash, `-f655md8fbd`**, computed from its contents, and the
Deployment's reference to it was rewritten to match. That is the next section's subject.

```
        image: shop:1.1
ana@laptop:~/shop$ kubectl kustomize deploy/overlays/staging | grep -E "^kind|^  name|namespace:|GREETING|name: shop-settings"
  GREETING: staging
kind: ConfigMap
  name: shop-settings-staging-ckt68hf7g8
  namespace: staging
kind: Service
  name: shop-staging
  namespace: staging
kind: Deployment
  name: shop-staging
```

Staging's objects carry the `-staging` suffix, references included, and its greeting is the overlay's.
