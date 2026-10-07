---
title: A disk that follows the name
version: 1
---

The second half of a StatefulSet is `volumeClaimTemplates`. **Each pod gets its own claim for a
disk, named after the pod**, made the first time the pod is created and never shared:

```
ana@laptop:~/shop$ kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-db-0   Bound    pvc-e5048645-5c4b-4e61-b898-edc75d14d061   64Mi       RWO            standard       <unset>                 15s
data-db-1   Bound    pvc-f7619570-411e-4eca-8f27-1fb14536c879   64Mi       RWO            standard       <unset>                 10s
data-db-2   Bound    pvc-119eb272-e680-438c-936c-e810a0b6c5d1   64Mi       RWO            standard       <unset>                 5s
```

`data-db-0`, `data-db-1`, `data-db-2`: the template's name, `data`, plus the pod's. Each is `Bound` to
a volume of its own, provided here by kind's local-path provisioner as a directory on the node where
the pod first ran. Lesson 26 opens claims, volumes and storage classes properly; what matters here is
the binding between a name and a disk.

## Deleting a member

`db-1` is given something to remember, and then deleted:

```
ana@laptop:~/shop$ kubectl exec db-1 -- sh -c "echo order-1042 > /data/last-order; ls /data"
born
last-order
ana@laptop:~/shop$ kubectl delete pod db-1
pod "db-1" deleted from default namespace
```

```
ana@laptop:~/shop$ kubectl get pod db-1 -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
db-1   1/1     Running   0          1s    10.244.1.6   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl exec db-1 -- cat /data/born /data/last-order
db-1
order-1042
```

**The pod that came back is `db-1`, and it has `db-1`'s data**: its `born` file still says `db-1`,
written on its first start, and `last-order` is the line written into the pod that was deleted. The
address changed, from `10.244.1.3` to `10.244.1.6`, which is why the previous section's advice was to
use the name. It came back on `shop-worker2`, the same node as before, because a local-path disk
exists on one node only and the pod has to go where its disk is.

## Scaling down keeps the disks

```
ana@laptop:~/shop$ kubectl scale statefulset db --replicas=1
statefulset.apps/db scaled
ana@laptop:~/shop$ kubectl get pods -l app=db
NAME   READY   STATUS        RESTARTS   AGE
db-0   1/1     Running       0          62s
db-1   1/1     Running       0          16s
db-2   1/1     Terminating   0          52s
ana@laptop:~/shop$ kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-db-0   Bound    pvc-e5048645-5c4b-4e61-b898-edc75d14d061   64Mi       RWO            standard       <unset>                 62s
data-db-1   Bound    pvc-f7619570-411e-4eca-8f27-1fb14536c879   64Mi       RWO            standard       <unset>                 57s
data-db-2   Bound    pvc-119eb272-e680-438c-936c-e810a0b6c5d1   64Mi       RWO            standard       <unset>                 52s
```

`db-2` goes first, from the top, and it is still `Terminating` fifteen seconds later because its
`sleep` ignores the polite signal and the kubelet waits out the thirty-second grace period; lesson 35
is about shutting down properly. **The three claims are all still there.** Kubernetes does not delete
a StatefulSet's disks when it scales down or even when the StatefulSet is deleted, because a disk is
the one thing in the cluster that cannot be recreated from a file. Scale back up and `db-2` gets
`data-db-2` again. Deleting them is a decision somebody makes on purpose.

| | Deployment | StatefulSet |
|---|---|---|
| pod names | random suffix, new on every replacement | `db-0`, `db-1`, … fixed |
| start and stop | all at once | one at a time, in order |
| disk | shared or none | one claim per pod, kept when the pod goes |
| reached through | one Service address, any pod | a headless Service: one name per pod |
