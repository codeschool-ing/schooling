---
title: Teaching the API server a new kind
version: 1
---

Before anything is defined, the API server has never heard of a Backup:

```
ana@laptop:~/shop$ kubectl get backups
error: the server doesn't have a resource type "backups"
```

**A CustomResourceDefinition is itself an ordinary object**, created with `kubectl apply`, and what it
describes is a new kind of object. The shop's team wants to declare its database backups the way it
declares everything else, so the kind is `Backup`:

```schooling-example
{"language": "yaml", "file": "backup-crd.yaml", "parts": [{"code": "apiVersion: apiextensions.k8s.io/v1\nkind: CustomResourceDefinition\nmetadata:\n  name: backups.shop.example.test\n", "note": "**The name is the plural and the group**, `backups.shop.example.test`. A group under a domain you own keeps your kinds from colliding with anybody else's."}, {"code": "spec:\n  group: shop.example.test\n  names:\n    kind: Backup\n    plural: backups\n    singular: backup\n    shortNames: [\"bk\"]\n  scope: Namespaced\n", "note": "How the new kind is spelled: `Backup` in manifests, `backups` and `backup` on the command line, `bk` for short. `Namespaced` puts each Backup in a namespace, like a Deployment."}, {"code": "  versions:\n  - name: v1\n    served: true\n    storage: true\n", "note": "One version, `v1`, served by the API and used for storage. A later `v2` would be added beside it, never in place of it."}, {"code": "    schema:\n      openAPIV3Schema:\n        type: object\n        required: [\"spec\"]\n        properties:\n          spec:\n            type: object\n            required: [\"database\", \"schedule\"]\n            properties:\n              database:\n                type: string\n              schedule:\n                type: string\n              keep:\n                type: integer\n                minimum: 1\n                maximum: 30\n                default: 7\n          status:\n            type: object\n            properties:\n              lastRun:\n                type: string\n", "note": "**The schema is the validation.** `database` and `schedule` are required; `keep` must be an integer from 1 to 30 and defaults to 7. Any field not listed is unknown. `status` gets a schema of its own."}, {"code": "    subresources:\n      status: {}\n", "note": "`subresources.status` makes `status` a separate part of the object, written by a different route than `spec`."}, {"code": "    additionalPrinterColumns:\n    - name: Database\n      type: string\n      jsonPath: .spec.database\n    - name: Schedule\n      type: string\n      jsonPath: .spec.schedule\n    - name: Keep\n      type: integer\n      jsonPath: .spec.keep\n    - name: Last run\n      type: string\n      jsonPath: .status.lastRun\n", "note": "The columns `kubectl get` prints, each one a path into the object."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f backup-crd.yaml
customresourcedefinition.apiextensions.k8s.io/backups.shop.example.test created
ana@laptop:~/shop$ kubectl api-resources --api-group=shop.example.test
NAME      SHORTNAMES   APIVERSION             NAMESPACED   KIND
backups   bk           shop.example.test/v1   true         Backup
```

The API server now serves `backups` in the group `shop.example.test`, version `v1`. **Nothing was
compiled, restarted or installed besides that one object.** The new kind is stored in etcd like every
other, has its own URL in the API, and works with `kubectl get`, `describe`, `delete`, `-o yaml`,
RBAC rules, and `watch`. All of that comes free, because the API server handles it the same way for every kind.

That is how most of the Kubernetes ecosystem extends the cluster. The Gateway API of lesson 16 is a
set of CRDs; so are cert-manager's certificates, Argo CD's applications, Prometheus's alert rules and
the VerticalPodAutoscaler of lesson 34. Listing them on any real cluster shows how much of it is
built this way:

```
kubectl get crds
```

The lab cluster of this lesson has only the one just created, so that command was not captured here.
