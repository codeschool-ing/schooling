---
title: Create, change, break, delete
version: 1
---

With the controller running in a second terminal and writing to `controller.log`, the Backup of lesson
43 is created again:

```yaml
apiVersion: shop.example.test/v1
kind: Backup
metadata:
  name: orders-nightly
spec:
  database: orders
  schedule: "0 3 * * *"
```

```
ana@laptop:~/shop/backup-controller$ kubectl apply -f nightly.yaml
backup.shop.example.test/orders-nightly created
ana@laptop:~/shop/backup-controller$ cat controller.log
2026/10/06 18:13:55 orders-nightly: created cronjob backup-orders-nightly (0 3 * * *)
ana@laptop:~/shop/backup-controller$ kubectl get cronjobs
NAME                    SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
backup-orders-nightly   0 3 * * *   <none>     False     0        <none>          2s
ana@laptop:~/shop/backup-controller$ kubectl get cronjob backup-orders-nightly -o jsonpath="{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}"; echo
Backup/orders-nightly
```

**Within one pass, a CronJob appeared, owned by the Backup.** The controller logged what it did, and the
owner reference names the Backup. The CronJob can be run on demand to see what it does:

```
ana@laptop:~/shop/backup-controller$ kubectl create job manual --from=cronjob/backup-orders-nightly
job.batch/manual created
ana@laptop:~/shop/backup-controller$ kubectl logs job/manual
would dump orders and keep 7 copies
```

The Job's pod printed what a real backup would do, with `keep` at the schema's default of 7.

## A change to what is wanted

```
ana@laptop:~/shop/backup-controller$ kubectl patch backup orders-nightly --type=merge -p '{"spec":{"schedule":"30 2 * * *"}}'
backup.shop.example.test/orders-nightly patched
ana@laptop:~/shop/backup-controller$ tail -n 1 controller.log
2026/10/06 18:14:05 orders-nightly: schedule "0 3 * * *" -> "30 2 * * *"
ana@laptop:~/shop/backup-controller$ kubectl get cronjobs
NAME                    SCHEDULE     TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
backup-orders-nightly   30 2 * * *   <none>     False     0        <none>          13s
```

The schedule was changed on the Backup, not on the CronJob, and within five seconds the controller saw
the difference and updated the CronJob. **People edit the object they understand, and the controller
translates it** into the objects Kubernetes understands.

## A change to what exists

Somebody deletes the CronJob by hand:

```
ana@laptop:~/shop/backup-controller$ kubectl delete cronjob backup-orders-nightly
cronjob.batch "backup-orders-nightly" deleted from default namespace
ana@laptop:~/shop/backup-controller$ tail -n 1 controller.log
2026/10/06 18:14:10 orders-nightly: created cronjob backup-orders-nightly (30 2 * * *)
ana@laptop:~/shop/backup-controller$ kubectl get cronjobs
NAME                    SCHEDULE     TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
backup-orders-nightly   30 2 * * *   <none>     False     0        <none>          5s
```

Recreated on the next pass, with the current schedule. The controller did not notice a deletion; it
noticed, as it does on every pass, that the CronJob it expects did not exist. That is the difference
between reacting to events and reconciling state, and it is why the same code handles a first
creation, an accidental deletion and a restart of the controller itself.

## Deleting the Backup

```
ana@laptop:~/shop/backup-controller$ kubectl delete backup orders-nightly
backup.shop.example.test "orders-nightly" deleted from default namespace
ana@laptop:~/shop/backup-controller$ kubectl get cronjobs,backups
No resources found in default namespace.
```

The Backup and its CronJob are both gone, and the controller has no code for deletion. **The owner
reference did it**: Kubernetes' garbage collector deletes objects whose owner no longer exists, so
cleaning up is declared when the object is created, not written as a separate path that might be
forgotten.
