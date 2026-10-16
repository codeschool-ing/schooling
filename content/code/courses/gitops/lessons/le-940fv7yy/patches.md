---
title: Patches, and the fields Kustomize already knows
version: 1
---

**An overlay changes the base in two ways: through fields Kustomize knows about, and through
patches for everything else.** `namespace`, `replicas`, `images` and the generators are the first
kind. Each says one thing, in one line, and Kustomize applies it to every object it fits. They
should be the first choice whenever one exists, because a reader sees intent rather than mechanics.

A patch is for the rest, and Kustomize takes two shapes of patch.

**A strategic merge patch** looks like a fragment of the object, and is merged into it. Production
gets resource requests and limits that staging does not, and the patch is the part of a Deployment
that says so. Here is `apps/bulletin/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: production
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
  - MESSAGE=Welcome to the bulletin.
patches:
- target:
    kind: Service
    name: bulletin
  patch: |-
    - op: add
      path: /spec/ports/0/nodePort
      value: 30081
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: bulletin
    spec:
      template:
        spec:
          containers:
          - name: bulletin
            resources:
              requests:
                cpu: 10m
                memory: 16Mi
              limits:
                memory: 32Mi
```

and `apps/bulletin/production/namespace.yaml` names `production` the way staging's names
`staging`. The second patch has no `target`: a strategic merge patch names its own object, and the
containers are matched by `name`, so the resources land on the `bulletin` container and nothing
else in the list moves.

**A JSON patch** is a list of operations on paths, `add`, `replace`, `remove`, and it is what both
overlays use for the Service's `nodePort`. The port is an element of a list with no name to match
on, so the patch says `/spec/ports/0/nodePort`: the first port. A position is a fragile thing to
join on: the base has exactly one port today, and a second port added at the front of the list would
move the patch onto the wrong one without any error. **Prefer a strategic
merge patch, and use a JSON patch where no field can be matched by name.**

```
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/production | awk 'BEGIN { RS = "---\n" } /kind: Deployment/'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bulletin
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: bulletin
  template:
    metadata:
      labels:
        app: bulletin
    spec:
      containers:
      - envFrom:
        - configMapRef:
            name: bulletin-95kb84mf4k
        image: localhost:5001/bulletin:1.1
        name: bulletin
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
        resources:
          limits:
            memory: 32Mi
          requests:
            cpu: 10m
            memory: 16Mi
```

`kubectl kustomize` shows production's Deployment with the base's fields, the overlay's replicas and
tag, and the patched resources, which is the whole of what production is.
