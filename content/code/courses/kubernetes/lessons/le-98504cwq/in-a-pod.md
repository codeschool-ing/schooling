---
title: The token inside a pod, and the roles that come built in
version: 1
---

A pipeline running outside the cluster asks for a token. **A program running inside it is handed
one**: a pod names its ServiceAccount, and the kubelet mounts a token for that account into every
container.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: reader
  namespace: shop
spec:
  serviceAccountName: deployer
  automountServiceAccountToken: true
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
```

`automountServiceAccountToken: true` is the default, written out here so the next paragraph has
something to point at. A pod that never talks to the API server should set it to `false`, because a
token nobody uses is still a token somebody can steal.

```
ana@laptop:~/shop$ kubectl apply -f reader.yaml
pod/reader created
ana@laptop:~/shop$ kubectl -n shop exec reader -- ls /var/run/secrets/kubernetes.io/serviceaccount
ca.crt
namespace
token
```

Three files: the CA certificate to check the server with, the namespace the pod is in, and the token.
Every client library looks in this directory first, which is why code inside a pod reaches the API
with no configuration at all. The token is a JWT, three base64 parts separated by dots, and the middle
part is readable:

```
ana@laptop:~/shop$ kubectl -n shop exec reader -- sh -c "cut -d. -f2 /var/run/secrets/kubernetes.io/serviceaccount/token | base64 -d 2>/dev/null | head -c 400"; echo
{"aud":["https://kubernetes.default.svc.cluster.local"],"exp":1822844376,"iat":1791308376,"iss":"https://kubernetes.default.svc.cluster.local","jti":"f2e06ac1-2404-43b4-ab2a-c7fd513106d8","kubernetes.io":{"namespace":"shop","node":{"name":"shop-worker","uid":"21ccd822-fa5c-4c4c-8653-d88148412cf5"},"pod":{"name":"reader","uid":"bfe00e13-54ec-4a1b-97c4-f41a42cc2e4c"},"serviceaccount":{"name":"deploy
```

**The token names the exact pod and node it was issued for.** Delete the pod and the token stops
being accepted, even before it expires, because the API server checks that the pod it names still
exists. The audience is the API server's own address, so another service that receives this token
should refuse it.

`exp` minus `iat` is 31,536,000 seconds, a year, which looks like the opposite of the ten minutes in
the previous section. The kubelet asked for about an hour and replaces the file before that hour is
up. The API server, by default, stretches the expiry to a year, so that old clients which read the
file once and never again keep working. A pod that holds no permissions loses nothing to that
stretch, and that is the real protection.

## The roles that come with the cluster

Writing every Role by hand is not necessary. The cluster ships with ClusterRoles meant to be bound to
people:

```
ana@laptop:~/shop$ kubectl get clusterroles view edit admin cluster-admin
NAME            CREATED AT
view            2026-10-06T17:39:02Z
edit            2026-10-06T17:39:02Z
admin           2026-10-06T17:39:02Z
cluster-admin   2026-10-06T17:39:02Z
ana@laptop:~/shop$ kubectl get clusterroles --no-headers | wc -l
77
```

| ClusterRole | grants |
|---|---|
| `view` | read most objects, but not Secrets |
| `edit` | read and write most objects, including Secrets, but not roles or bindings |
| `admin` | nearly everything in a namespace, including its roles and bindings |
| `cluster-admin` | everything, everywhere |

A ClusterRole is a Role that is not tied to one namespace, so it can also cover objects that have no
namespace, such as nodes. **How far it reaches depends on the binding, not on the role.** Bound with
a ClusterRoleBinding, `edit` applies in every namespace. Bound with a RoleBinding inside `shop`, the
same `edit` applies in `shop` only. That second form is the usual way to give a team its own
namespace: one RoleBinding to `admin`, and nothing at cluster scope. This course did not run it.

The other 73 of the 77 are mostly for the cluster's own components, with names starting `system:`.
The scheduler and the controllers each have exactly the permissions their job needs, granted by
the same mechanism as the pipeline's.
