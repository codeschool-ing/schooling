---
title: A claim, followed call by call
version: 1
---

The claim is lesson 26's, with the CSI class named:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: csi-hostpath-fast
  resources:
    requests:
      storage: 1Gi
```

```
ana@laptop:~/shop$ kubectl apply -f claim.yaml
persistentvolumeclaim/data created
ana@laptop:~/shop$ kubectl get pvc data
NAME   STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS        VOLUMEATTRIBUTESCLASS   AGE
data   Pending                                      csi-hostpath-fast   <unset>                 3s
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=data -o custom-columns=REASON:.reason,MESSAGE:.message
REASON                 MESSAGE
WaitForFirstConsumer   waiting for first consumer to be created before binding
```

`Pending`, waiting for a consumer, for the same reason as before: the class binds on first use, so
the volume is made on whichever node the pod lands on.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "date > /data/first; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data
```

```
ana@laptop:~/shop$ kubectl apply -f writer.yaml
pod/writer created
ana@laptop:~/shop$ kubectl get pod writer -o wide
NAME     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
writer   1/1     Running   0          2s    10.244.2.4   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl get pvc data
NAME   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        VOLUMEATTRIBUTESCLASS   AGE
data   Bound    pvc-50aa12b5-b5a8-4132-a5f7-5f2fdef6f6fa   1Gi        RWO            csi-hostpath-fast   <unset>                 5s
```

The scheduler put `writer` on `shop-worker2`, and the claim was bound to a new PersistentVolume within
seconds. The volume says who made it and how to find it again:

```
ana@laptop:~/shop$ kubectl get pv -o jsonpath='{.items[0].spec.csi}'; echo
{"driver":"hostpath.csi.k8s.io","volumeAttributes":{"kind":"fast","storage.kubernetes.io/csiProvisionerIdentity":"1791311334737-7540-hostpath.csi.k8s.io-shop-worker2"},"volumeHandle":"cc853bf3-c1b3-11f1-8644-4a042d320914"}
ana@laptop:~/shop$ kubectl get pv -o jsonpath='{.items[0].spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0]}'; echo
{"key":"topology.hostpath.csi/node","operator":"In","values":["shop-worker2"]}
```

**`driver` names the CSI driver, and `volumeHandle` is the driver's own id for the volume**, which
Kubernetes stores and hands back on every later call without understanding it. For a cloud disk it
would be the disk's id in the cloud. `kind: fast` is the class's parameter, carried along. The node
affinity uses the topology key the driver reported, so this volume, like lesson 26's, ties every
future pod to `shop-worker2`.

## The calls, in order

The driver logs each call it receives. On `shop-worker2`, with repeats in a row collapsed by `uniq`:

```
ana@laptop:~/shop$ kubectl logs pod/csi-hostpathplugin-7r2rb -c hostpath | grep -o 'GRPC call: [^ ]*' | uniq
GRPC call: /csi.v1.Identity/GetPluginInfo
GRPC call: /csi.v1.Identity/Probe
GRPC call: /csi.v1.Identity/GetPluginInfo
GRPC call: /csi.v1.Identity/GetPluginCapabilities
GRPC call: /csi.v1.Controller/ControllerGetCapabilities
GRPC call: /csi.v1.Node/NodeGetInfo
GRPC call: /csi.v1.Controller/GetCapacity
GRPC call: /csi.v1.Node/NodeGetInfo
GRPC call: /csi.v1.Controller/CreateVolume
GRPC call: /csi.v1.Controller/GetCapacity
GRPC call: /csi.v1.Node/NodeGetCapabilities
GRPC call: /csi.v1.Node/NodeStageVolume
GRPC call: /csi.v1.Node/NodeGetCapabilities
GRPC call: /csi.v1.Node/NodePublishVolume
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One node, shop-worker2, holding the driver's pod with three containers: csi-provisioner, node-driver-registrar and hostpath, which share a socket. The API server holds the claim. csi-provisioner watches the API server for claims and calls CreateVolume and DeleteVolume on the socket. node-driver-registrar tells the kubelet where the socket is. The kubelet calls NodeStageVolume and NodePublishVolume on the same socket to mount the volume into the pod writer.\"><defs><marker id=\"csi-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"csi-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"csi-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">API server</text><text x=\"95.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">PVC data</text><rect x=\"200\" y=\"14\" width=\"500\" height=\"276\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"216\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">node shop-worker2</text><rect x=\"230\" y=\"50\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">csi-provisioner</text><rect x=\"230\" y=\"130\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">node-driver-registrar</text><rect x=\"500\" y=\"90\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hostpath</text><text x=\"590.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">csi.sock</text><rect x=\"230\" y=\"210\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kubelet</text><rect x=\"500\" y=\"210\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pod writer</text><text x=\"590.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/data</text><path d=\"M228 72 L172 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-paper-dim)\"></path><text x=\"95\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">watches claims</text><path d=\"M402 72 L498 104\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-amber)\"></path><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">CreateVolume</text><path d=\"M315 176 L315 208\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-paper-dim)\"></path><text x=\"322\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">registers the socket</text><path d=\"M402 222 L540 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#csi-ah-phosphor)\"></path><text x=\"470\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">NodePublish</text><path d=\"M402 240 L498 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#csi-ah-phosphor)\"></path></svg>", "caption": "Two callers, one socket. The sidecar makes the controller calls on behalf of the API, and the kubelet makes the node calls on behalf of the pod."}
```

Read from the top, the log is the whole life of the driver so far:

1. **Identity and capabilities.** When the sidecars and the kubelet first connected, they asked who
   the driver is, whether it is ready, and what it can do.
2. **`GetCapacity`.** The provisioner asked how much space the node has, which became the
   CSIStorageCapacity objects of the previous section.
3. **`CreateVolume`.** The provisioner saw the claim, now with its node chosen, and asked the
   driver for a volume. The driver made a directory and returned its handle.
4. **`NodeStageVolume`, then `NodePublishVolume`.** The kubelet, starting `writer`, asked the driver
   to prepare the volume on the node and then to make it appear at the path inside the pod. For a
   block device, staging is where it gets formatted and mounted once per node; publishing bind-mounts
   it into each pod that uses it.

No Kubernetes component ever touched the storage itself. **Every action on it was a call to the
driver**, which is the contract CSI exists for.
