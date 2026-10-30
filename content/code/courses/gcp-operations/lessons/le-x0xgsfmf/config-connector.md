---
title: Config Connector, infrastructure as Kubernetes objects
version: 1
---

**Config Connector describes Google Cloud resources as Kubernetes objects, and a controller in a cluster
keeps the real resources matching them, continuously.** Lessons 5 and 6 used Terraform, which acts when a
person or a pipeline runs it and is silent in between. Config Connector does not wait: a bucket deleted by
hand in the console comes back within minutes, because the controller sees that the object in the cluster
says it should exist. **Nothing in this lesson ran.** Config Connector needs a GKE cluster and
Infrastructure Manager needs a project; neither has an emulator. It is taught from Google's documentation,
and the files below are written from it.

The shop's assets bucket, as a Config Connector object:

```yaml
# kcc/assets-bucket.yaml
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  name: planner-dev-shop-assets
  namespace: shop
  annotations:
    cnrm.cloud.google.com/project-id: planner-dev
  labels:
    team: shop
spec:
  location: SOUTHAMERICA-EAST1
  uniformBucketLevelAccess: true
  versioning:
    enabled: true
```

It is applied like any Kubernetes object, `kubectl apply -f kcc/assets-bucket.yaml`, and from then on the
cluster owns the bucket. Four things follow from that, and each one is a difference from Terraform:

- **There is no state file.** The object in the cluster is the desired state, and the bucket in Google is
  the actual one. The question lesson 6 spent a lesson on (where is the state, who locked it) does not
  arise; the question becomes who can edit objects in the `shop` namespace.
- **There is no plan.** `kubectl apply` changes the object and the controller acts on it. A reviewed change
  is a pull request on the YAML, and the diff is the only preview there is, which reads well for a label and
  badly for a change that forces a replacement.
- **Drift is corrected, not reported.** A change made by hand is undone. That is the strongest guarantee in
  this lesson, and it is also how somebody's emergency fix in the console disappears at 3 a.m. without a
  word.
- **Deleting the object deletes the resource**, unless the object carries
  `cnrm.cloud.google.com/deletion-policy: abandon`. A namespace deleted by mistake takes every resource
  declared in it.

## Who the controller acts as

The controller acts in Google Cloud as a service account, through Workload Identity (`gcp-compute` lesson
15), and that account needs the roles to create and change everything the cluster declares. **Anybody who
can create objects in a namespace Config Connector watches can create resources with that account's
permissions.** Kubernetes RBAC on the namespace is therefore Google Cloud IAM by another name, and it is
granted with the same care: one service account per namespace, with only the roles that namespace's
resources need.

## When it fits

Config Connector fits a team that already runs GKE and manages its applications with Kubernetes manifests:
the bucket an application uses sits in the same repository, the same review and the same `kubectl` as the
`Deployment` that uses it. It fits badly a team without a cluster, because it needs one running all the time
just to hold the descriptions, and a team whose resources are mostly networks, projects and organisation
policies, which live comfortably outside any one cluster.
