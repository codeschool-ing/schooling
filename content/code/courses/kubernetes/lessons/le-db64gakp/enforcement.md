---
title: A policy is only as real as the plugin that enforces it
version: 1
---

Two namespaces this time. `shop` runs the shop, its Service, and a busybox pod called `front` that
plays the shop's web front end. `other` runs a busybox pod called `stranger`, which belongs to some
other team. Nothing stops `stranger` from calling the shop, because nothing stops any pod from
calling any other. After `./up.sh`, these make all of it:

```sh
kubectl create namespace shop
kubectl create namespace other
kubectl -n shop create deployment shop --image=shop:1.0 --replicas=2
kubectl -n shop expose deployment shop --port 80 --target-port 8080
kubectl -n shop run front --image=busybox:1.37 --labels=app=front --restart=Never --command -- sleep 3600
kubectl -n other run stranger --image=busybox:1.37 --restart=Never --command -- sleep 3600
```

The first policy closes the `shop` namespace to everything:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: shop
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

**`podSelector: {}` selects every pod in the namespace**, and `policyTypes: [Ingress]` with no
`ingress` rules means none of them accepts a connection from anybody. That is the usual first policy
for a namespace: deny everything, then allow what is needed, one path at a time.

## Applied, and ignored

The usual lab cluster runs kind's own network plugin, kindnet:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -l app=kindnet -o name
pod/kindnet-4jljk
pod/kindnet-m8cch
pod/kindnet-q6l2x
ana@laptop:~/shop$ kubectl apply -f deny-all.yaml
networkpolicy.networking.k8s.io/deny-all created
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
shop 1.0 on shop-774b84ff8c-pd5v4
```

**The policy was accepted, and `stranger` still got its answer.** The API server stored the object and
checked its syntax. It does not enforce it, and it has no way to know whether anything will. That job
belongs to the network plugin. Kindnet carries a policy engine, and its log says what happened on this
machine:

```
ana@laptop:~/shop$ kubectl -n kube-system logs $(kubectl -n kube-system get pods -l app=kindnet -o name | head -n 1) | grep -A 1 'syncing nftables'
I1006 18:17:37.603768       1 controller.go:817] "syncing nftables rules" logger="nftables-sync" error=<
	conn.Receive: netlink receive: no such file or directory
```

The engine programs the kernel through nftables, and this laptop's kernel refused the request. Nothing
else complained. **On your machine the engine may well start**, and then `stranger` is refused already
on this cluster; the log shows which you have. The point stands either way, because the API server
accepted the policy without knowing which of the two would happen. On a cluster whose plugin has no policy support at all, there is not even this line:
**a NetworkPolicy that nothing enforces looks exactly like one that works, until somebody tests it.**

## The same policy with Calico

The second cluster is made without kindnet and runs Calico instead. It is the same cluster with kind's
plugin left out, in a file beside `cluster.yaml`.

`calico.yaml`:

```yaml
# cluster.yaml without kind's own network plugin, so that Calico can be
# installed instead. Calico's manifest assumes pods get addresses from
# 192.168.0.0/16, so the cluster is told the same.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
  podSubnet: 192.168.0.0/16
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
  serverTLSBootstrap: true
nodes:
- role: control-plane
- role: worker
- role: worker
```

`up.sh` takes it as an argument and stops before waiting for the nodes, which cannot be `Ready` with no
plugin at all. Calico comes from its own manifest, and then the nodes are ready; the six commands from
the top of this section put the namespaces and pods back:

```sh
./up.sh calico.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/calico.yaml
kubectl -n kube-system rollout status daemonset/calico-node
kubectl wait --for=condition=Ready nodes --all
```

The recording machine could not reach the registry Calico's manifest names, so its copy pointed at the
same images on Docker Hub, where Calico also publishes them. One `calico-node` per node:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
NAME                READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
calico-node-cdb4z   1/1     Running   0          25s   172.18.0.4   shop-worker          <none>           <none>
calico-node-d67ph   1/1     Running   0          25s   172.18.0.2   shop-worker2         <none>           <none>
calico-node-lrn2c   1/1     Running   0          25s   172.18.0.3   shop-control-plane   <none>           <none>
```

The same `stranger`, the same shop, before and after the same file:

```
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
shop 1.0 on shop-774b84ff8c-zmqss
ana@laptop:~/shop$ kubectl apply -f deny-all.yaml
networkpolicy.networking.k8s.io/deny-all created
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
wget: download timed out
command terminated with exit code 1
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
wget: download timed out
command terminated with exit code 1
```

Before the policy, the answer came back. After it, `stranger` timed out, and so did `front`, the
shop's own front end in the same namespace. **Deny-all means all**, including neighbours. The next
section opens the path `front` needs.

Choosing a network plugin is partly choosing this: Calico and Cilium enforce NetworkPolicy, Flannel
on its own does not, and a managed cluster's default plugin may need policy support switched on.
Lesson 18 compared plugins; this is the column of that comparison that most often matters.
