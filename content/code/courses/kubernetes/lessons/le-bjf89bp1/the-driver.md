---
title: What a CSI driver is made of
version: 1
---

**A CSI driver is an ordinary program that answers a fixed set of gRPC calls over a Unix socket.** The
calls are defined by the Container Storage Interface specification, which Kubernetes shares with other
orchestrators, and they come in three groups: identity (who are you, are you alive), controller
(create, delete, attach a volume) and node (mount it on this machine). A cloud's disk driver answers
them by calling the cloud's API; the driver here answers them by making a directory.

This lesson installs the CSI host-path driver, the Kubernetes project's own example driver, which keeps
every volume in a directory on a node. It is a teaching driver and nothing more: the data never leaves
the node, and losing the node loses it. Its value here is that it is small enough to watch. After
`./up.sh`, it comes from the project's own manifests for a cluster of several nodes, with the
permissions its provisioner needs from that project's release:

```sh
P=https://raw.githubusercontent.com/kubernetes-csi/external-provisioner/v6.3.0/deploy/kubernetes
H=https://raw.githubusercontent.com/kubernetes-csi/csi-driver-host-path/v1.18.0/deploy/kubernetes-distributed/hostpath
kubectl apply -f $P/rbac.yaml -f $H/csi-hostpath-driverinfo.yaml -f $H/csi-hostpath-plugin.yaml -f $H/csi-hostpath-storageclass-fast.yaml
kubectl rollout status daemonset/csi-hostpathplugin
```

**Those files run one more container than the transcripts below show**, `liveness-probe`, which only
checks that the driver answers; on the machine this course was recorded on, the driver, its two
sidecars and their images were built from the projects' source, because their registry could not be
reached from it, and the liveness container was left out. So your pods say `4/4` where these say
`3/3`, and your driver is v1.17.1, the version the release's manifest names.

```
ana@laptop:~/shop$ kubectl get csidriver
NAME                  ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES                  AGE
hostpath.csi.k8s.io   false            true             true              <unset>         false               Persistent,Ephemeral   4s
```

The CSIDriver object is how the driver tells the cluster what it needs. `ATTACHREQUIRED false`: there
is no separate attach step, because a directory on a node is already where it needs to be; a cloud
disk does need attaching to a machine first. `STORAGECAPACITY true`: the driver reports how much space
each node has left, which the scheduler then uses.

```
ana@laptop:~/shop$ kubectl get pods -l app.kubernetes.io/name=csi-hostpathplugin -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
csi-hostpathplugin-7r2rb   3/3     Running   0          4s    10.244.2.3   shop-worker2   <none>           <none>
csi-hostpathplugin-zwkc9   3/3     Running   0          4s    10.244.1.3   shop-worker    <none>           <none>
ana@laptop:~/shop$ kubectl get pods -l app.kubernetes.io/name=csi-hostpathplugin -o jsonpath="{.items[0].spec.containers[*].name}"; echo
csi-provisioner node-driver-registrar hostpath
```

One copy per worker node, three containers each. **Only `hostpath` is the driver; the other two are
sidecars the Kubernetes project publishes**, and every CSI driver ships with some of them, because
they translate between Kubernetes objects and CSI calls so that the vendor does not have to:

| container | job |
|---|---|
| `hostpath` | the driver: answers the CSI calls on its socket |
| `csi-provisioner` | watches the API for claims and calls `CreateVolume` and `DeleteVolume` |
| `node-driver-registrar` | tells the node's kubelet where the driver's socket is |

```
ana@laptop:~/shop$ kubectl get csinodes
NAME                 DRIVERS   AGE
shop-control-plane   0         42s
shop-worker          1         31s
shop-worker2         1         31s
```

`DRIVERS 1` on each worker is the registrar's work: each kubelet now knows this driver. The
control-plane node runs no copy, so it has none.

## The class and the capacity

```
ana@laptop:~/shop$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
csi-hostpath-fast    hostpath.csi.k8s.io     Delete          WaitForFirstConsumer   false                  4s
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  37s
ana@laptop:~/shop$ kubectl get csistoragecapacities -o custom-columns=CLASS:.storageClassName,CAPACITY:.capacity,NODE:.nodeTopology.matchLabels
CLASS               CAPACITY   NODE
csi-hostpath-fast   100Gi      map[topology.hostpath.csi/node:shop-worker2]
csi-hostpath-fast   100Gi      map[topology.hostpath.csi/node:shop-worker]
```

`csi-hostpath-fast` is the class the project ships with the driver; its parameter `kind: fast` is
passed through to the driver with every volume, which is how one driver offers several kinds of
storage. Each worker reports 100 GiB available in it, a number the driver was told to advertise and
not a measurement of the disk. Beside it, kind's own `standard` class from lesson 26 is still the
default.
