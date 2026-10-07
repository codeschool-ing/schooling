---
title: The words of the cluster
version: 1
---

The rest of this course uses about a dozen words without stopping to define them, so they are
defined here, once, and each points at the lesson that gives it depth. **The one to hold onto is
that most of them name a kind of object**, and the others name the machines and programs that act
on those objects.

| word | what it is | in depth |
|---|---|---|
| cluster | a set of machines run as one, with one API | lesson 4 |
| node | one machine of the cluster, real or virtual, running a kubelet | lesson 4 |
| control plane | the programs that store objects and decide: API server, etcd, scheduler, controllers | lesson 4 |
| pod | one or more containers that run together on one node and share an address | lesson 9 |
| controller | a program that watches one type and makes the world match its spec | lesson 44 |
| Deployment, ReplicaSet | the objects that keep a number of identical pods running | lesson 10 |
| Service | one stable address in front of a changing set of pods | lesson 15 |
| namespace | a name scope for objects, used to divide a cluster between teams | lesson 20 |
| label | a key and value on an object, chosen by you | this section |
| selector | a question about labels, which picks the objects that answer it | this section |

## Labels: how one object finds another

A pod does not belong to a ReplicaSet by being listed inside it. **It belongs because it carries
the labels the ReplicaSet's selector asks for.** `kubectl create deployment web` gave every pod the
label `app=web`, and the ReplicaSet added `pod-template-hash`:

```
ana@laptop:~/shop$ kubectl get pods --show-labels
NAME                   READY   STATUS    RESTARTS   AGE   LABELS
web-768c88b7c7-2cfcg   1/1     Running   0          1s    app=web,pod-template-hash=768c88b7c7
web-768c88b7c7-rwz26   1/1     Running   0          1s    app=web,pod-template-hash=768c88b7c7
web-768c88b7c7-vdp2x   1/1     Running   0          1s    app=web,pod-template-hash=768c88b7c7
```

The same labels answer your questions. `-l app=web` is a selector, and `-o wide` adds the address
and the node of each pod:

```
ana@laptop:~/shop$ kubectl get pods -l app=web -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
web-768c88b7c7-2cfcg   1/1     Running   0          1s    10.244.1.2   shop-worker    <none>           <none>
web-768c88b7c7-rwz26   1/1     Running   0          1s    10.244.2.3   shop-worker2   <none>           <none>
web-768c88b7c7-vdp2x   1/1     Running   0          1s    10.244.2.2   shop-worker2   <none>           <none>
```

The scheduler placed one copy on `shop-worker` and two on `shop-worker2`, and nobody asked it to
split them that way. Lesson 29 shows how to ask. Selecting by label instead of by name is what lets
the whole cluster keep working while pods come and go: a Service, a ReplicaSet and a network policy
all find their pods with a selector, so a replacement pod with the right labels is found the moment
it exists.

## Namespaces: scopes, not places

A fresh cluster already has five:

```
ana@laptop:~/shop$ kubectl get namespaces
NAME                 STATUS   AGE
default              Active   35s
kube-node-lease      Active   35s
kube-public          Active   35s
kube-system          Active   35s
local-path-storage   Active   31s
```

`default` is where Ana's objects went because she named no other. `kube-system` holds the cluster's
own machinery, and listing it shows that **the control plane and the node agents run as pods too**:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system
NAME                                         READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-9fw4r                     1/1     Running   0          25s
coredns-559f6c778d-v6p5k                     1/1     Running   0          25s
etcd-shop-control-plane                      1/1     Running   0          32s
kindnet-mfvl8                                1/1     Running   0          20s
kindnet-q7jtj                                1/1     Running   0          25s
kindnet-zb5wv                                1/1     Running   0          20s
kube-apiserver-shop-control-plane            1/1     Running   0          32s
kube-controller-manager-shop-control-plane   1/1     Running   0          32s
kube-proxy-2mpqg                             1/1     Running   0          20s
kube-proxy-tqhf2                             1/1     Running   0          25s
kube-proxy-wrwp9                             1/1     Running   0          20s
kube-scheduler-shop-control-plane            1/1     Running   0          34s
```

There is one `kube-proxy` and one `kindnet` per node, three of each, and one of each control-plane
component, on `shop-control-plane`. A namespace groups these by purpose and says nothing about
where they run: the `kube-system` pods are spread over all three nodes, side by side with Ana's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A cluster containing three nodes side by side. Each node holds pods, and each pod holds one container. The shop's pods, drawn in the colour of namespace default, sit on two different nodes, and etcd and kube-proxy, drawn dashed for namespace kube-system, sit on all three.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cluster</text><rect x=\"150\" y=\"44\" width=\"170\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-control-plane</text><rect x=\"164\" y=\"90\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"197\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">etcd</text><rect x=\"164\" y=\"218\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"197\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"335\" y=\"44\" width=\"170\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"349\" y=\"150\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"382\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">web</text><rect x=\"349\" y=\"218\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"382\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"520\" y=\"44\" width=\"170\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"534\" y=\"150\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">web</text><rect x=\"608\" y=\"150\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"641\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">web</text><rect x=\"534\" y=\"218\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"567\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-proxy</text><text x=\"24\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">namespace</text><text x=\"24\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">default</text><text x=\"24\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace</text><text x=\"24\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kube-system</text></svg>", "caption": "Nodes, pods and containers nest inside each other. A namespace does not: it cuts across the nodes and groups objects by purpose."}
```
