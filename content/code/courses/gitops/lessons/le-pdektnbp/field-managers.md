---
title: Who last touched a field
version: 1
---

**Every object remembers which client set each of its fields.** Since server-side apply, the API
server keeps `managedFields` on every object: a list of *managers*, each with the fields it set and
the time it last did. Flux applies as `kustomize-controller`; `kubectl scale` is `kubectl`; an
autoscaler is its own name. Without any audit log configured, an object can say who changed it last,
field by field.

A change by hand, the kind lesson 1 called drift, made a moment before Flux's next pass:

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=5
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin -o json --show-managed-fields | jq -c '.metadata.managedFields[] | {manager, operation, time, replicas: (.fieldsV1."f:spec"."f:replicas" != null)}'
{"manager":"kustomize-controller","operation":"Apply","time":"2026-10-16T04:40:00Z","replicas":false}
{"manager":"kubectl","operation":"Update","time":null,"replicas":true}
{"manager":"kube-controller-manager","operation":"Update","time":"2026-10-16T04:53:57Z","replicas":false}
ana@laptop:~/fleet$ flux reconcile kustomization staging >/dev/null
► annotating Kustomization staging in flux-system namespace
✔ Kustomization annotated
◎ waiting for Kustomization reconciliation
✔ applied revision main@sha1:42c811e7415a8d67d9632a5889e32afd2f4083cd
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin -o json --show-managed-fields | jq -c '.metadata.managedFields[] | {manager, operation, time, replicas: (.fieldsV1."f:spec"."f:replicas" != null)}'
{"manager":"kustomize-controller","operation":"Apply","time":"2026-10-16T04:53:57Z","replicas":true}
{"manager":"kube-controller-manager","operation":"Update","time":"2026-10-16T04:53:57Z","replicas":false}
```

Before Flux's pass, `kubectl` owns `spec.replicas`, with an `Update`. After it, the entry for
`kubectl` is gone and `kustomize-controller` owns the field again, with an `Apply` and a new time:
Flux took the field back, and the object now says so.

This is weaker evidence than an audit log, and worth knowing for that reason. It names a client, not
a person: every `kubectl` user is `kubectl`. It keeps the last writer of each field and forgets the
ones before. And it is part of the object, so it goes when the object is deleted and is rewritten
when Flux takes the field back. **It answers "did something other than Flux touch this?"** quickly
and from any cluster, and for "who, and when, exactly" the next section turns on the record that was
designed for it.
