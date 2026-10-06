---
title: Applying overlays, and why the ConfigMap has a hash
version: 1
---

`kubectl apply -k` builds an overlay and applies the result in one step:

```
ana@laptop:~/shop$ kubectl create namespace staging && kubectl create namespace production
namespace/staging created
namespace/production created
ana@laptop:~/shop$ kubectl apply -k deploy/overlays/staging
configmap/shop-settings-staging-ckt68hf7g8 created
service/shop-staging created
deployment.apps/shop-staging created
ana@laptop:~/shop$ kubectl apply -k deploy/overlays/production
configmap/shop-settings-f655md8fbd created
service/shop created
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get deployments -A -l env -L env
NAMESPACE    NAME           READY   UP-TO-DATE   AVAILABLE   AGE   ENV
production   shop           3/3     3            3           1s    production
staging      shop-staging   1/1     1            1           1s    staging
```

**One base, two environments, side by side**, each in its namespace and labelled with its name. Nothing
in the base mentions either of them.

## A change in the base

The greeting changes in the base, so every environment should get it:

```
ana@laptop:~/shop$ sed -i 's/GREETING=hello/GREETING=welcome/' deploy/base/kustomization.yaml
ana@laptop:~/shop$ kubectl diff -k deploy/overlays/production | grep -E "^[-+] " | head -n 12
-  generation: 1
+  generation: 2
-            name: shop-settings-f655md8fbd
+            name: shop-settings-k59c4b8286
+  GREETING: welcome
+  creationTimestamp: "2026-10-06T21:06:33Z"
+  labels:
+    env: production
+  name: shop-settings-k59c4b8286
+  namespace: production
+  uid: 94b071bc-15e7-4427-8696-b5745ebc833a
```

`kubectl diff` compares what the overlay would produce with what the cluster has. The ConfigMap is a
new object, `shop-settings-k59c4b8286`, because its contents changed and so did the hash; and the
Deployment changed too, because its reference to the ConfigMap changed. **That second change is the
point of the hash**: a Deployment whose pod template changes rolls out new pods, so the new setting
reaches every pod. A ConfigMap edited in place under the same name would change nothing in the running
pods' environment, as lesson 13 found.

```
ana@laptop:~/shop$ kubectl apply -k deploy/overlays/production
configmap/shop-settings-k59c4b8286 created
service/shop unchanged
deployment.apps/shop configured
ana@laptop:~/shop$ kubectl -n production get configmaps
NAME                       DATA   AGE
kube-root-ca.crt           1      4s
shop-settings-f655md8fbd   1      4s
shop-settings-k59c4b8286   1      2s
```

`deployment.apps/shop configured`, and the rollout followed. The old ConfigMap is still there, unused.
`kubectl apply` never deletes what an overlay stops producing; cleaning up is done with
`kubectl apply --prune` and a label selector, or by a GitOps tool, which lesson 39 is about.

| | Helm | Kustomize |
|---|---|---|
| differences live in | values, fed into templates | overlays and patches over plain manifests |
| files kubectl can apply on their own | no, they are templates | yes |
| a record of releases and rollback | yes, `helm history` and `rollback` | no; the history is git's |
| installing third-party software | the common way | possible, less common |

The two are not rivals. A common arrangement is Helm for software other people publish, Kustomize for
your own applications, and `kubectl kustomize` able to render a Helm chart inside an overlay when both
meet.
