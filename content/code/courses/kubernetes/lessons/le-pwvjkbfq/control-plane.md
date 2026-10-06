---
title: The control plane, opened up
version: 1
---

**"The master" is still a common name for the control plane, and it suggests one program that runs
the cluster.** There are four, plus a database, and they are ordinary processes you can list. On the
laptop's cluster they run on the node called `shop-control-plane`:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=shop-control-plane
NAME                                         READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
coredns-559f6c778d-mtg29                     1/1     Running   0          14s   10.244.0.3   shop-control-plane   <none>           <none>
coredns-559f6c778d-snbdh                     1/1     Running   0          14s   10.244.0.2   shop-control-plane   <none>           <none>
etcd-shop-control-plane                      1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
kindnet-5ddmg                                1/1     Running   0          14s   172.18.0.3   shop-control-plane   <none>           <none>
kube-apiserver-shop-control-plane            1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
kube-controller-manager-shop-control-plane   1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
kube-proxy-vzh6c                             1/1     Running   0          14s   172.18.0.3   shop-control-plane   <none>           <none>
kube-scheduler-shop-control-plane            1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
```

Four of those rows are the control plane: `etcd`, `kube-apiserver`, `kube-controller-manager` and
`kube-scheduler`, each with the node's name added. The rest run on this node too, and belong to
other lessons: `coredns` answers names inside the cluster (lesson 15), and `kindnet` and
`kube-proxy` run on every node, as the next section shows.

| component | what it does |
|---|---|
| `kube-apiserver` | the only door. Every request, from `kubectl` or from another component, arrives here, is checked and is stored |
| `etcd` | a key-value database that holds every object. Only the API server talks to it |
| `kube-scheduler` | finds pods that have no node yet and chooses one for each |
| `kube-controller-manager` | runs the built-in controllers: deployments, ReplicaSets, nodes, jobs and dozens more |

## How a control plane starts before there is one

The API server is what runs pods, so who runs the API server? **The kubelet on that node does, from
files**, without asking anybody:

```
ana@laptop:~/shop$ docker exec shop-control-plane ls /etc/kubernetes/manifests
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
```

A file in `/etc/kubernetes/manifests` is a *static pod*: the kubelet watches the directory and runs
whatever is described there, and the API server shows a read-only copy of it so that `kubectl` can
list it. kubeadm, which kind uses to build every node, writes these four files; lesson 47 runs kubeadm
by hand. The file is also the API server's configuration, and three of its flags say a lot:

```
ana@laptop:~/shop$ docker exec shop-control-plane grep -E "^ +- --(etcd-servers|secure-port|service-cluster-ip-range)" /etc/kubernetes/manifests/kube-apiserver.yaml
    - --etcd-servers=https://127.0.0.1:2379
    - --secure-port=6443
    - --service-cluster-ip-range=10.96.0.0/16
```

It reaches etcd at `127.0.0.1:2379`, on the same machine, and over TLS. It listens on port `6443`,
which is what `kubectl` dials. And it hands Services their addresses from `10.96.0.0/16`, a range
that exists only inside the cluster.

## What etcd holds

Everything. The objects of lesson 2 are keys under `/registry`, by type, namespace and name. This
reads the keys only, with etcd's own client, from inside the etcd pod and with its certificates:

```
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/deployments/default --prefix --keys-only
/registry/deployments/default/web

ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/pods/default --prefix --keys-only
/registry/pods/default/web-768c88b7c7-mlp9j

/registry/pods/default/web-768c88b7c7-v5pxq
```

There is the Deployment Ana created and the two pods it led to. **Losing etcd is losing the
cluster's memory**: the running containers would carry on, and nothing would know what they were
for. That is why a production control plane runs three or five etcd members, which agree on every
write by a majority, and why lesson 47 takes a backup of it before anything else. And that is why only one
program may talk to it: every check the API server makes on a request would be pointless if another
door led straight to the data.
