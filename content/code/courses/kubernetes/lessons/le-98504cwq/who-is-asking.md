---
title: Who is asking
version: 1
---

The API server handles every request in the same order. **First it authenticates: it works out who sent
the request. Then it authorises: it decides whether that identity may do this particular thing.** A
request that fails the first step is a 401; one that passes it and fails the second is a 403. RBAC,
role-based access control, is the second step, and it is what this lesson is about.

Start with the identity you have been using all along:

```
ana@laptop:~/shop$ kubectl auth whoami
ATTRIBUTE                                           VALUE
Username                                            kubernetes-admin
Groups                                              [kubeadm:cluster-admins system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [X509SHA256=ef21c7d51d53537947c3ffce2489c735a4e8bb5a66a20f081dae87b6e3f324a0]
ana@laptop:~/shop$ kubectl get clusterrolebinding kubeadm:cluster-admins -o custom-columns=ROLE:.roleRef.name,SUBJECT:.subjects[0].name
ROLE            SUBJECT
cluster-admin   kubeadm:cluster-admins
```

`kubectl auth whoami` asks the API server what it concluded about you. The answer came from the
client certificate in your kubeconfig: the user `kubernetes-admin`, in the group
`kubeadm:cluster-admins`. **There is no user object behind that name.** Kubernetes stores no people.
A person is whatever name a certificate or an identity provider's token carries, and RBAC grants
things to those names. The second command shows the grant that made every earlier lesson work: a
ClusterRoleBinding that gives the group the ClusterRole `cluster-admin`, which may do anything,
anywhere.

## An identity for a program

Programs get a different kind of identity, and this one IS an object. A **ServiceAccount** lives in a
namespace, and the API server issues tokens for it. A deploy pipeline is the classic case: it needs
to change Deployments in one namespace and nothing else.

```
ana@laptop:~/shop$ kubectl create namespace shop
namespace/shop created
ana@laptop:~/shop$ kubectl create serviceaccount deployer -n shop
serviceaccount/deployer created
ana@laptop:~/shop$ kubectl auth can-i list pods -n shop --as=system:serviceaccount:shop:deployer
no
```

`kubectl auth can-i` asks the authoriser a yes-or-no question, and `--as` asks it on somebody else's
behalf. The new account may not even list pods. **Nothing was denied explicitly; nothing was granted,
and RBAC has no other default.**

To see the refusal the way a pipeline would, the next command asks for a token and calls the API
directly with `curl`. Before the capture, the cluster's CA certificate and the API server's address
were saved into `ca.crt` and `server.txt`, which is how `curl` checks it is talking to the real
server.

```
ana@laptop:~/shop$ TOKEN=$(kubectl create token deployer -n shop --duration=10m); curl -s --cacert ca.crt -H "Authorization: Bearer $TOKEN" $(cat server.txt)/api/v1/namespaces/shop/pods | head -n 8
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:shop:deployer\" cannot list resource \"pods\" in API group \"\" in the namespace \"shop\"",
  "reason": "Forbidden",
  "details": {
```

**Authentication worked**: the message names `system:serviceaccount:shop:deployer`, which is how a
ServiceAccount appears to RBAC, as `system:serviceaccount:<namespace>:<name>`. The refusal came from
the second step, and it says exactly what was missing: the verb `list`, the resource `pods`, the API
group `""`, the namespace `shop`. Those four are the shape every RBAC rule has.

The token from `kubectl create token` lasts ten minutes here, because `--duration=10m` asked for that.
A short life is the point: a token that leaks from a pipeline's log is worth very little ten minutes
later.
