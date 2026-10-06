---
title: Where the volume really is, and how it goes away
version: 1
---

A kind node is a container, so `docker exec` can look inside the directory the driver keeps its
volumes in:

```
ana@laptop:~/shop$ docker exec shop-worker2 ls /var/lib/csi-hostpath-data
cc853bf3-c1b3-11f1-8644-4a042d320914
state.json
```

**One directory, named with the `volumeHandle` the PersistentVolume recorded**, beside the driver's
own bookkeeping file. Inside the pod, the same storage is `/data`:

```
ana@laptop:~/shop$ kubectl exec writer -- cat /data/first
Tue Oct  6 18:29:01 UTC 2026
ana@laptop:~/shop$ kubectl exec writer -- sh -c 'mount | grep /data'
/dev/vda on /data type ext4 (rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534)
```

The file the container wrote is there. The mount line names `/dev/vda`, the disk of the machine the
node runs on, because a host-path volume is a directory on that disk, bind-mounted into the pod; a
cloud driver's volume would show its own device here instead.

## Deleting, call by call

```
ana@laptop:~/shop$ kubectl delete pod writer
pod "writer" deleted from default namespace
ana@laptop:~/shop$ kubectl delete pvc data
persistentvolumeclaim "data" deleted from default namespace
ana@laptop:~/shop$ kubectl get pv
No resources found
```

The PersistentVolume went with the claim, because the class's reclaim policy is `Delete`, as in
lesson 26. This time the driver's log shows what that meant:

```
ana@laptop:~/shop$ kubectl logs pod/csi-hostpathplugin-7r2rb -c hostpath | grep -o 'GRPC call: [^ ]*' | grep -E 'Unpublish|Unstage|DeleteVolume'
GRPC call: /csi.v1.Node/NodeUnpublishVolume
GRPC call: /csi.v1.Node/NodeUnstageVolume
GRPC call: /csi.v1.Controller/DeleteVolume
```

**The kubelet unpublished and unstaged the volume when the pod went; the provisioner asked for
`DeleteVolume` when the claim went.** The same three steps as creation, backwards, made by the same
two callers.

```
ana@laptop:~/shop$ docker exec shop-worker2 ls /var/lib/csi-hostpath-data
state.json
```

The directory is gone. On a cloud, the same sequence detaches and deletes a real disk, and it is the
reason `Retain` exists.

| CSI call | made by | when |
|---|---|---|
| `CreateVolume` | `csi-provisioner` | a claim needs a volume |
| `NodeStageVolume` | the kubelet | a node first needs the volume |
| `NodePublishVolume` | the kubelet | a pod on that node mounts it |
| `NodeUnpublishVolume`, `NodeUnstageVolume` | the kubelet | the pod, then the node, no longer need it |
| `DeleteVolume` | `csi-provisioner` | the claim is deleted and the policy is `Delete` |

Snapshots, resizing and attaching to a machine are further calls with further sidecars, left out of
this lab's driver. Lesson 28 is about protecting what a database keeps on a volume.
