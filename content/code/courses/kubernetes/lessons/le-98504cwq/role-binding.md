---
title: A Role says what, a RoleBinding says who
version: 1
---

**Access is granted by two objects, and keeping them apart is the design.** A Role is a list of rules,
each one naming API groups, resources and verbs. A RoleBinding attaches a Role to one or more
subjects: users, groups or ServiceAccounts. The same Role can be bound to the pipeline today and to a
second pipeline tomorrow without being copied.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: shop
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer
  namespace: shop
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployer
subjects:
- kind: ServiceAccount
  name: deployer
  namespace: shop
```

The first rule covers Deployments, which live in the API group `apps`; the second covers pods, which
live in the core group, written as the empty string `""`. **`pods/log` is a subresource and has to be
named on its own**: permission to read a pod does not include permission to read its logs. The verbs
are the API's own: `get` reads one object, `list` and `watch` read many, `create`, `update` and
`patch` write. There is no `delete` in this list, on purpose.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Inside the namespace shop, three objects. In the middle a RoleBinding named deployer. An arrow labelled subjects points left to the ServiceAccount deployer. An arrow labelled roleRef points right to the Role deployer, whose rules allow get, list, watch, create, update and patch on deployments in the apps group, and get, list and watch on pods and pods/log. Below: anything no rule names is refused.\"><defs><marker id=\"rbac-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"175\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: shop</text><rect x=\"40\" y=\"80\" width=\"170\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ServiceAccount</text><text x=\"125.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deployer</text><rect x=\"270\" y=\"80\" width=\"140\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RoleBinding</text><text x=\"340.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deployer</text><rect x=\"470\" y=\"56\" width=\"214\" height=\"112\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"577.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Role deployer</text><text x=\"577.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">deployments (apps):</text><text x=\"577.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get list watch create</text><text x=\"577.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">update patch</text><text x=\"577.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pods, pods/log: get list watch</text><path d=\"M270 112 L212 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rbac-ah-amber)\"></path><text x=\"241\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">subjects</text><path d=\"M410 112 L468 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rbac-ah-amber)\"></path><text x=\"439\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">roleRef</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Anything no rule names is refused.</text></svg>", "caption": "The binding is the only object that knows both sides. Delete it and the account and the role both still exist, and grant nothing."}
```

```
ana@laptop:~/shop$ kubectl apply -f deployer-role.yaml
role.rbac.authorization.k8s.io/deployer created
rolebinding.rbac.authorization.k8s.io/deployer created
ana@laptop:~/shop$ TOKEN=$(kubectl create token deployer -n shop --duration=10m); curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" $(cat server.txt)/api/v1/namespaces/shop/pods | head -n 6
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "708"
  },
```

The same `curl`, with a fresh token, now gets a `PodList` back. The namespace is empty, so the list
is too; what matters is that the API server answered instead of refusing.

## Asking before relying on it

`kubectl auth can-i` is the quickest way to check a grant without writing a client:

```
ana@laptop:~/shop$ kubectl auth can-i create deployments -n shop --as=system:serviceaccount:shop:deployer
yes
ana@laptop:~/shop$ kubectl auth can-i delete deployments -n shop --as=system:serviceaccount:shop:deployer
no
ana@laptop:~/shop$ kubectl auth can-i get secrets -n shop --as=system:serviceaccount:shop:deployer
no
ana@laptop:~/shop$ kubectl auth can-i list pods -n default --as=system:serviceaccount:shop:deployer
no
ana@laptop:~/shop$ kubectl auth can-i create pods/exec -n shop --as=system:serviceaccount:shop:deployer
no
```

Each answer follows from the Role and from nothing else. Creating a Deployment is allowed. Deleting one
is not, because `delete` is not in the verbs. Secrets were never mentioned. The `default` namespace is
outside the binding, **because a RoleBinding only grants inside its own namespace.** And `pods/exec`
is a subresource nobody named, so opening a shell in a pod is refused even though reading the pod is
allowed.

`--list` prints everything the identity may do in the namespace:

```
ana@laptop:~/shop$ kubectl auth can-i --list -n shop --as=system:serviceaccount:shop:deployer | head -n 8
Resources                                       Non-Resource URLs                      Resource Names   Verbs
selfsubjectreviews.authentication.k8s.io        []                                     []               [create]
selfsubjectaccessreviews.authorization.k8s.io   []                                     []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                                     []               [create]
deployments.apps                                []                                     []               [get list watch create update patch]
pods/log                                        []                                     []               [get list watch]
pods                                            []                                     []               [get list watch]
clustertrustbundles.certificates.k8s.io         []                                     []               [get list watch]
```

Our two rules are in there, in rows four to six. The rows around them come from roles that every
authenticated identity is bound to, such as the right to ask these very questions about itself.

## Acting as the account

`--as` works on every `kubectl` command, not only on `can-i`. It is called impersonation, and it is
itself a permission: the administrator has it, the pipeline does not.

```
ana@laptop:~/shop$ kubectl --as=system:serviceaccount:shop:deployer -n shop create deployment shop --image=shop:1.0
deployment.apps/shop created
ana@laptop:~/shop$ kubectl --as=system:serviceaccount:shop:deployer -n shop delete deployment shop
Error from server (Forbidden): deployments.apps "shop" is forbidden: User "system:serviceaccount:shop:deployer" cannot delete resource "deployments" in API group "apps" in the namespace "shop"
```

**The create worked and the delete was refused, with the same message shape as the `curl` earlier.**
A pipeline with this Role can roll out a new version, and cannot remove the application by mistake or
on anybody else's behalf. That is least privilege in practice: start from nothing, and grant the verbs
that the job actually uses.
