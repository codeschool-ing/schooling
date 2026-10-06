---
title: The claim, the volume and the class
version: 1
---

**An application should not have to know which disk it gets.** On a laptop it is a directory, in one
cloud a block device, in another a network file system. Kubernetes keeps that out of the pod with
three objects: the pod names a PersistentVolumeClaim, the claim is bound to a PersistentVolume, and a
StorageClass made the volume.

The class comes first, because a cluster has one before anybody asks:

```
ana@laptop:~/shop$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  64s
ana@laptop:~/shop$ kubectl get storageclass standard -o jsonpath="{.provisioner} {.reclaimPolicy} {.volumeBindingMode}{\"\\n\"}"
rancher.io/local-path Delete WaitForFirstConsumer
```

kind ships one class, `standard`, marked as the default, whose provisioner is the local-path
provisioner: each volume it makes is a directory on one node. A cloud's default class names the
cloud's disk service instead, and the rest of this section reads exactly the same there.

## Claiming

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: orders
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
```

The claim asks for one gibibyte that one node at a time may mount for writing, `ReadWriteOnce`. It
names no class, so it gets the default.

```
ana@laptop:~/shop$ kubectl apply -f claim.yaml
persistentvolumeclaim/orders created
ana@laptop:~/shop$ kubectl get pvc orders
NAME     STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
orders   Pending                                      standard       <unset>                 3s
ana@laptop:~/shop$ kubectl get events --field-selector involvedObject.name=orders -o custom-columns=REASON:.reason,MESSAGE:.message
REASON                 MESSAGE
WaitForFirstConsumer   waiting for first consumer to be created before binding
```

**`Pending`, and that is on purpose.** `volumeBindingMode: WaitForFirstConsumer` tells the provisioner
to wait for a pod that uses the claim, because for storage that lives on one node or in one zone, the
volume has to be made where that pod will run. Making it first would let the scheduler later find the
pod a node the volume cannot reach.

A pod that mounts the claim by name:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "echo order-2001 >> /data/orders.txt; sleep 3600"]
    volumeMounts:
    - name: orders
      mountPath: /data
  volumes:
  - name: orders
    persistentVolumeClaim:
      claimName: orders
```

```
ana@laptop:~/shop$ kubectl apply -f writer.yaml
pod/writer created
ana@laptop:~/shop$ kubectl get pvc orders
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
orders   Bound    pvc-641c36a7-ac96-4f30-9e71-768f12a33ad3   1Gi        RWO            standard       <unset>                 8s
ana@laptop:~/shop$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-641c36a7-ac96-4f30-9e71-768f12a33ad3   1Gi        RWO            Delete           Bound    default/orders   standard       <unset>                          2s
ana@laptop:~/shop$ kubectl get pv $(kubectl get pvc orders -o jsonpath="{.spec.volumeName}") -o jsonpath="{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0]}"; echo
{"key":"kubernetes.io/hostname","operator":"In","values":["shop-worker"]}
```

The pod arrived, the scheduler chose `shop-worker`, and the provisioner made a PersistentVolume there
and bound it to the claim. **The volume records its node**, so every pod that uses this claim from now
on is scheduled onto `shop-worker`. That is the price of node-local storage. A cloud disk records a
zone instead of a node, which is a looser version of the same tie.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Left to right: the pod writer mounts the claim orders. The PersistentVolumeClaim orders asks for 1Gi, ReadWriteOnce. It is bound to a PersistentVolume, pvc-641c…, 1Gi, which records the node shop-worker. Below the claim, the StorageClass standard, provisioner rancher.io/local-path, made the volume when the claim asked. The volume is a directory on the node.\"><defs><marker id=\"pv-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pv-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"pv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"pv-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Pod writer</text><text x=\"90.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">mountPath: /data</text><rect x=\"220\" y=\"40\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PVC orders</text><text x=\"310.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1Gi · ReadWriteOnce</text><rect x=\"460\" y=\"40\" width=\"240\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PV pvc-641c…</text><text x=\"580.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1Gi · Delete</text><text x=\"580.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">node: shop-worker</text><rect x=\"220\" y=\"160\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">StorageClass standard</text><text x=\"310.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rancher.io/local-path</text><rect x=\"490\" y=\"160\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a directory on shop-worker</text><path d=\"M162 68 L218 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pv-ah-paper-dim)\"></path><text x=\"190\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">asks</text><path d=\"M402 68 L458 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pv-ah-phosphor)\" marker-start=\"url(#pv-ah-phosphor)\"></path><text x=\"430\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">bound</text><path d=\"M402 188 L430 188 L430 120 L540 120 L540 98\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#pv-ah-amber)\"></path><text x=\"484\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">made it</text><path d=\"M580 98 L580 158\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "The pod knows only the claim's name. Which disk, which node and which provider are the claim's and the class's business."}
```

| object | written by | says |
|---|---|---|
| PersistentVolumeClaim | the application's author | how much, and how it will be mounted |
| PersistentVolume | the provisioner, or an operator by hand | where the storage really is |
| StorageClass | the cluster's operator | how to make a volume, and what happens to it afterwards |
