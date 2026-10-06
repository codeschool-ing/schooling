---
title: A backup of etcd, and the restore that proves it
version: 1
---

Every object in this course lived in etcd. **Back it up and the cluster can be rebuilt; lose it and
every Deployment, Secret and role has to be written again from wherever their files are.** etcd is a
pod on the control plane, and `etcdctl` inside it talks to it with the client certificate kubeadm made:

```
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member list -w table
┌──────────────────┬─────────┬────────────────────┬─────────────────────────┬─────────────────────────┬────────────┐
│        ID        │ STATUS  │        NAME        │       PEER ADDRS        │      CLIENT ADDRS       │ IS LEARNER │
├──────────────────┼─────────┼────────────────────┼─────────────────────────┼─────────────────────────┼────────────┤
│ ed3b372f1d693cef │ started │ shop-control-plane │ https://172.18.0.6:2380 │ https://172.18.0.6:2379 │      false │
└──────────────────┴─────────┴────────────────────┴─────────────────────────┴─────────────────────────┴────────────┘
ana@laptop:~/shop$ kubectl create configmap before-backup --from-literal=note=present
configmap/before-backup created
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/lib/etcd/snapshot.db
{"level":"info","ts":"2026-10-06T21:57:09.824140Z","caller":"snapshot/v3_snapshot.go:83","msg":"created temporary db file","path":"/var/lib/etcd/snapshot.db.part"}
{"level":"info","ts":"2026-10-06T21:57:09.829554Z","logger":"client","caller":"v3/maintenance.go:236","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2026-10-06T21:57:09.831863Z","caller":"snapshot/v3_snapshot.go:96","msg":"fetching snapshot","endpoint":"https://127.0.0.1:2379"}
{"level":"info","ts":"2026-10-06T21:57:09.849682Z","logger":"client","caller":"v3/maintenance.go:302","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2026-10-06T21:57:09.852325Z","caller":"snapshot/v3_snapshot.go:111","msg":"fetched snapshot","endpoint":"https://127.0.0.1:2379","size":"2.1 MB","took":"28.074664ms","etcd-version":"3.7.0"}
{"level":"info","ts":"2026-10-06T21:57:09.852387Z","caller":"snapshot/v3_snapshot.go:121","msg":"saved","path":"/var/lib/etcd/snapshot.db"}
Snapshot saved at /var/lib/etcd/snapshot.db
Server version 3.7.0
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdutl snapshot status /var/lib/etcd/snapshot.db -w table
┌──────────┬──────────┬────────────┬────────────┬─────────┐
│   HASH   │ REVISION │ TOTAL KEYS │ TOTAL SIZE │ VERSION │
├──────────┼──────────┼────────────┼────────────┼─────────┤
│ 778b46c4 │      783 │        453 │     2.1 MB │   3.7.0 │
└──────────┴──────────┴────────────┴────────────┴─────────┘
ana@laptop:~/shop$ docker cp shop-control-plane:/var/lib/etcd/snapshot.db etcd-snapshot.db && ls -l etcd-snapshot.db
-rw------- 1 root root 2064416 Oct  6 18:57 etcd-snapshot.db
```

One member: this cluster has one control-plane node, so etcd has no copy anywhere else, and that is
the case a backup exists for. A cluster built to survive the loss of a machine runs three or five
members, so a majority survives one or two failures. More members do not replace a backup, because a
`kubectl delete` is replicated to all of them just as faithfully.

The ConfigMap `before-backup` was created just before the snapshot, so the snapshot holds it. The
snapshot is one file of 2.1 MB with 453 keys, and the last command copied it **off the machine**. A backup
on the disk of the node it protects is lost with that node.

## The restore

Now the ConfigMap is deleted, and the cluster is put back to the snapshot:

```
ana@laptop:~/shop$ kubectl delete configmap before-backup
configmap "before-backup" deleted from default namespace
ana@laptop:~/shop$ docker exec shop-control-plane sh -c 'mkdir -p /root/stopped && mv /etc/kubernetes/manifests/*.yaml /root/stopped/'
ana@laptop:~/shop$ docker exec shop-control-plane etcdutl snapshot restore /var/lib/etcd/snapshot.db --data-dir /var/lib/etcd-restored --name shop-control-plane --initial-cluster shop-control-plane=https://172.18.0.6:2380 --initial-advertise-peer-urls https://172.18.0.6:2380 2>&1 | tail -n 1
2026-10-06T21:57:24Z	info	snapshot/v3_snapshot.go:334	restored snapshot	{"path": "/var/lib/etcd/snapshot.db", "wal-dir": "/var/lib/etcd-restored/member/wal", "data-dir": "/var/lib/etcd-restored", "snap-dir": "/var/lib/etcd-restored/member/snap", "initial-memory-map-size": 10737418240}
ana@laptop:~/shop$ docker exec shop-control-plane sed -i 's#^\( *\)path: /var/lib/etcd$#\1path: /var/lib/etcd-restored#' /root/stopped/etcd.yaml
ana@laptop:~/shop$ docker exec shop-control-plane grep -n 'etcd-restored' /root/stopped/etcd.yaml
91:      path: /var/lib/etcd-restored
ana@laptop:~/shop$ docker exec shop-control-plane sh -c 'mv /root/stopped/*.yaml /etc/kubernetes/manifests/'
ana@laptop:~/shop$ kubectl get configmap before-backup -o jsonpath="{.data.note}"; echo
present
ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   78s   v1.37.0
shop-worker          Ready    <none>          68s   v1.37.0
shop-worker2         Ready    <none>          42s   v1.37.0
```

Four steps, and each one is a file being moved:

1. **Stop the control plane** by moving its manifests out of the directory the kubelet watches. Restoring
   underneath a running etcd would corrupt both.
2. **Restore the snapshot into a new directory.** `etcdutl` writes a fresh data directory, with this
   member's name and peer address, rather than overwriting the old one; the old one stays as a way back.
3. **Point the etcd pod at it.** The manifest mounts a directory of the node as its data; `sed` changes
   that path, and `grep` confirms the one line it changed.
4. **Start the control plane** by moving the manifests back.

`present`: the deleted ConfigMap is back, and the nodes are as they were. So is everything else, to the
second the snapshot was taken, **and everything written after that second is gone**. A daily backup
means up to a day of changes lost, and the gap between backups is the number to agree on before the day
it is needed.

A restore nobody has rehearsed is the backup's weak half. The commands above take minutes on a cluster
made for the purpose, and that is the place to find out that the certificate paths are different or
that `etcdutl` is not installed.
