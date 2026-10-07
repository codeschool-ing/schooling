---
title: Everything in the cluster is an object
version: 1
---

**The usual first picture is that Kubernetes runs containers. It does, eventually, but what you talk
to is a store of records.** Every node, every copy of the shop, every rule about who may do what is
an object kept by the API server, with a type and a name, and almost everything else in the cluster
is a program that reads those objects and acts on them. Learning Kubernetes is mostly learning the
types.

The laptop's cluster from lesson 5 has three nodes, and each node is itself an object:

```
ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   32s   v1.37.0
shop-worker          Ready    <none>          17s   v1.37.0
shop-worker2         Ready    <none>          17s   v1.37.0
```

## The types, listed by the cluster itself

The API server can say which types it knows:

```
ana@laptop:~/shop$ kubectl api-resources --no-headers | wc -l
71
ana@laptop:~/shop$ kubectl api-resources | head -n 12
NAME                                SHORTNAMES   APIVERSION                        NAMESPACED   KIND
bindings                                         v1                                true         Binding
componentstatuses                   cs           v1                                false        ComponentStatus
configmaps                          cm           v1                                true         ConfigMap
endpoints                           ep           v1                                true         Endpoints
events                              ev           v1                                true         Event
limitranges                         limits       v1                                true         LimitRange
namespaces                          ns           v1                                false        Namespace
nodes                               no           v1                                false        Node
persistentvolumeclaims              pvc          v1                                true         PersistentVolumeClaim
persistentvolumes                   pv           v1                                false        PersistentVolume
pods                                po           v1                                true         Pod
```

**Seventy-one types**, and this cluster has nothing installed beyond what kind puts in. Each row
gives the name you type, a short name (`po` for `pods`), the API group and version it belongs to, and
whether an object of that type lives inside a namespace or belongs to the whole cluster: a pod is
always in a namespace, a node never is. Lesson 43 adds a type of your own to this list.

## One command, five objects

Ana asks for three copies of the shop, and then lists three types at once:

```
ana@laptop:~/shop$ kubectl create deployment web --image=shop:1.0 --replicas=3
deployment.apps/web created
ana@laptop:~/shop$ kubectl get deployments,replicasets,pods
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   3/3     3            3           2s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-768c88b7c7   3         3         3       2s

NAME                       READY   STATUS    RESTARTS   AGE
pod/web-768c88b7c7-2cfcg   1/1     Running   0          1s
pod/web-768c88b7c7-rwz26   1/1     Running   0          1s
pod/web-768c88b7c7-vdp2x   1/1     Running   0          1s
```

She created one object, a Deployment named `web`. **The cluster made four more**: a ReplicaSet,
whose name adds a hash of the pod template, `768c88b7c7`, and three Pods, whose names add five
random characters to that. Nobody typed those names. Two controllers did the work: the deployment
controller made the ReplicaSet, and the ReplicaSet controller made the pods. Lesson 10 takes that
chain apart.

## Spec is what you asked for, status is what is true

Every object that does something has two halves, and the cluster keeps them apart on purpose.

```
ana@laptop:~/shop$ kubectl get deployment web -o custom-columns=NAME:.metadata.name,WANTED:.spec.replicas,READY:.status.readyReplicas,IMAGE:.spec.template.spec.containers[0].image
NAME   WANTED   READY   IMAGE
web    3        3       shop:1.0
```

`WANTED` reads `.spec.replicas`, which Ana set. `READY` reads `.status.readyReplicas`, which a
controller wrote after counting. **When the two agree, the loop of lesson 1 has nothing to do**; when
they differ, the difference is the work. Here is one of the pods, the first lines of the object as
the API server stores it:

```
ana@laptop:~/shop$ POD=$(kubectl get pods -l app=web -o name | head -n 1); echo $POD
pod/web-768c88b7c7-2cfcg
ana@laptop:~/shop$ kubectl get $POD -o yaml | head -n 24
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2026-10-06T16:26:39Z"
  generateName: web-768c88b7c7-
  generation: 1
  labels:
    app: web
    pod-template-hash: 768c88b7c7
  name: web-768c88b7c7-2cfcg
  namespace: default
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: web-768c88b7c7
    uid: c1eb7232-604f-41c3-b768-1fffb6b37199
  resourceVersion: "658"
  uid: 5b9a9a38-ad25-469f-8f2d-d464e8c7b0da
spec:
  containers:
  - image: shop:1.0
    imagePullPolicy: IfNotPresent
```

`metadata` says what the object is: its `name`, its `namespace`, its `labels`, and an
`ownerReferences` entry naming the ReplicaSet that made it, which is how the chain of the last
section is recorded. `spec` begins below it, with the container and its image. The status half is
further down the same document, written by the cluster rather than by Ana:

```
ana@laptop:~/shop$ kubectl get $POD -o custom-columns=PHASE:.status.phase,IP:.status.podIP,NODE:.spec.nodeName
PHASE     IP           NODE
Running   10.244.1.2   shop-worker
```

`Running` is the phase, `10.244.1.2` the address the pod was given, and `shop-worker` the node the
scheduler put it on. None of those three was in what Ana asked for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"An object drawn as four stacked parts. apiVersion and kind say what type it is. metadata says which one it is: name, namespace, labels, owner. spec, written by you, says what should be true: three replicas of shop:1.0. status, written by the cluster, says what is true: three ready. A controller compares spec with status.\"><defs><marker id=\"an-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">apiVersion · kind</text><text x=\"440\" y=\"43\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">apps/v1 · Deployment</text><text x=\"480\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which type</text><rect x=\"40\" y=\"76\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">metadata</text><text x=\"440\" y=\"99\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">name: web · labels: app=web</text><text x=\"480\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which one</text><rect x=\"40\" y=\"132\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spec</text><text x=\"440\" y=\"155\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replicas: 3 · image: shop:1.0</text><text x=\"480\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what should be true</text><rect x=\"40\" y=\"188\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">status</text><text x=\"440\" y=\"211\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">readyReplicas: 3</text><text x=\"480\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what is true</text><text x=\"480\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">written by you</text><text x=\"480\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">written by the cluster</text><path d=\"M30 143 L22 143 L22 199 L30 199\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a controller compares them</text></svg>", "caption": "Spec and status are kept apart so that the difference between them can be read, and acted on."}
```

## The API documents itself

Every field has a description that the API server serves, so the reference is never more than one
command away:

```
ana@laptop:~/shop$ kubectl explain deployment.spec.replicas
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: replicas <integer>


DESCRIPTION:
    Number of desired pods. This is a pointer to distinguish between explicit
    zero and not specified. Defaults to 1.
    
```

`kubectl explain` walks any path through a type, `deployment.spec.template.spec.containers` as easily
as this one, and its answer comes from the version of Kubernetes the cluster actually runs.
