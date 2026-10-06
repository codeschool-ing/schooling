---
title: What survives what
version: 1
---

The writer appends `order-2001` to a file on the claim each time it starts. Delete the pod and create
it again:

```
ana@laptop:~/shop$ kubectl delete pod writer
pod "writer" deleted from default namespace
ana@laptop:~/shop$ kubectl apply -f writer.yaml
pod/writer created
ana@laptop:~/shop$ kubectl exec writer -- cat /data/orders.txt
order-2001
order-2001
```

**Two lines: the second pod found the first one's data.** The claim outlived the pod, and the new pod
was scheduled onto `shop-worker`, where the volume is. This is the property the whole arrangement
exists for, and it holds for every way a pod can disappear, a rollout included.

## Deleting the claim

What happens to the data when the claim itself is deleted is the StorageClass's
`reclaimPolicy`, and the default class said `Delete`:

```
ana@laptop:~/shop$ kubectl delete pod writer
pod "writer" deleted from default namespace
ana@laptop:~/shop$ kubectl delete pvc orders
persistentvolumeclaim "orders" deleted from default namespace
ana@laptop:~/shop$ kubectl get pv
No resources found
```

**The volume, and the directory with `order-2001` in it, are gone.** With `Delete`, removing a claim
removes its storage, on a laptop and in a cloud alike, where it deletes the disk. That is convenient
for scratch environments and a disaster for a database somebody deleted the claim of by mistake.

`Retain` is the other policy. A second class, the same provisioner, one line different:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: keep
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

A claim called `ledger` in that class, a pod to make the volume, and then the same two deletions:

```
ana@laptop:~/shop$ kubectl apply -f keep.yaml
storageclass.storage.k8s.io/keep created
ana@laptop:~/shop$ sed "s/name: orders/name: ledger/; s/storage: 1Gi/storage: 1Gi\n  storageClassName: keep/" claim.yaml | kubectl apply -f -
persistentvolumeclaim/ledger created
ana@laptop:~/shop$ sed "s/claimName: orders/claimName: ledger/; s/name: writer/name: keeper/" writer.yaml | kubectl apply -f -
pod/keeper created
ana@laptop:~/shop$ kubectl delete pod keeper
pod "keeper" deleted from default namespace
ana@laptop:~/shop$ kubectl delete pvc ledger
persistentvolumeclaim "ledger" deleted from default namespace
ana@laptop:~/shop$ kubectl get pv -o custom-columns=NAME:.metadata.name,CLAIM:.spec.claimRef.name,POLICY:.spec.persistentVolumeReclaimPolicy,STATUS:.status.phase
```

**The volume is still there, `Released`**: its claim is gone, and the data in it is untouched. It will
not be bound to a new claim on its own, because it still remembers the old one; an operator decides
what happens next, which is the point. Recovering it means clearing that memory, the `claimRef`, so a
new claim can bind to it, or copying the data out. Deleting it, when nobody needs it any more, is a
deliberate `kubectl delete pv`, and with `Retain` the disk behind it in a cloud stays until somebody
deletes that as well.

| `reclaimPolicy` | the claim is deleted | right for |
|---|---|---|
| `Delete` | the volume and its storage are removed | caches, test environments, anything rebuilt easily |
| `Retain` | the volume stays, `Released`, data intact | databases and anything nobody can rebuild |

A deleted claim is not the only risk to data, and none of this is a backup. Lesson 28 is about
databases in the cluster and what protects them.
