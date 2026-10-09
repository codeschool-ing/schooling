---
title: The kubeconfig file and its contexts
version: 1
---

**kubectl keeps no state of its own about clusters.** Everything it knows is in one file,
`~/.kube/config`, and a request goes wherever that file says. Ana now has two clusters on the
laptop, the `shop` cluster the lessons use and a `study` one beside it, made from the same file and
left alone, so that there is a second cluster to switch to. kind makes the newest one the current
context, and the last line points `kubectl` back at `shop`:

```sh
./up.sh
kind create cluster --name study --config cluster.yaml --quiet
kubectl config use-context kind-shop
```

kind wrote both into the file:

```
ana@laptop:~/shop$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO     NAMESPACE
*         kind-shop    kind-shop    kind-shop    
          kind-study   kind-study   kind-study   
```

A **context** is a name for three things at once: a cluster (where the API server is), a user (the
credentials to present) and, optionally, a namespace. The asterisk marks the current context, the
one every command uses unless told otherwise. `--minify` shows the file reduced to that one:

```
ana@laptop:~/shop$ kubectl config view --minify
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://127.0.0.1:44489
  name: kind-shop
contexts:
- context:
    cluster: kind-shop
    user: kind-shop
  name: kind-shop
current-context: kind-shop
kind: Config
users:
- name: kind-shop
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
```

Three lists — `clusters`, `contexts`, `users` — and the context joins one entry of the first to one
of the third. The server is `https://127.0.0.1:44489`, the port kind published for this cluster's
API server, and the certificates are elided here. **The file holds working credentials**: whoever
can read it is an administrator of both clusters, so it is treated like a private key, never
committed and never pasted into a ticket.

## Switching

```
ana@laptop:~/shop$ kubectl config use-context kind-study
Switched to context "kind-study".
ana@laptop:~/shop$ kubectl get nodes
NAME                  STATUS     ROLES           AGE   VERSION
study-control-plane   NotReady   control-plane   11s   v1.37.0
study-worker          NotReady   <none>          1s    v1.37.0
study-worker2         NotReady   <none>          1s    v1.37.0
ana@laptop:~/shop$ kubectl config use-context kind-shop
Switched to context "kind-shop".
ana@laptop:~/shop$ kubectl --context kind-study get nodes -o name
node/study-control-plane
node/study-worker
node/study-worker2
```

`use-context` changes the current context in the file, so it lasts until the next switch, in every
terminal. The `study` nodes are still `NotReady` because that cluster had been started seconds
before; the point is that `kubectl` reached them. For a single command against another cluster,
`--context` leaves the file alone, which is the safer habit in scripts: **a forgotten
`use-context` is how a command meant for a test cluster reaches production.**

## Namespaces, and the default one

A context can carry a namespace, and then every command without `-n` happens there:

```
ana@laptop:~/shop$ kubectl create namespace dev
namespace/dev created
ana@laptop:~/shop$ kubectl config set-context --current --namespace=dev
Context "kind-shop" modified.
ana@laptop:~/shop$ kubectl get pods
No resources found in dev namespace.
```

`dev` exists and is empty. The same request with `-n` reaches another namespace, and
`--all-namespaces`, or `-A`, reaches all of them:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -l component=etcd
NAME                      READY   STATUS    RESTARTS   AGE
etcd-shop-control-plane   1/1     Running   0          46s
ana@laptop:~/shop$ kubectl get pods --all-namespaces --no-headers | wc -l
13
```

Thirteen pods across the cluster, every one of them the cluster's own. **A namespace changes where
a name is looked up, nothing else**: it does not isolate the network or limit what a pod may use
unless something else is set up to do that, which lessons 20 and 24 do.
