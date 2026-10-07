---
title: Um backup do etcd, e a restauração que o prova
version: 1
---

Todo objeto deste curso viveu no etcd. **Faça backup dele e o cluster pode ser reconstruído; perca-o e
todo Deployment, Secret e papel tem de ser escrito de novo a partir de onde os arquivos estiverem.** O
etcd é um pod no control plane, e o `etcdctl` dentro dele fala com ele usando o certificado de cliente
que o kubeadm fez:

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

Um membro: este cluster tem um nó de control plane, então o etcd não tem cópia em lugar nenhum, e é para
esse caso que um backup existe. Um cluster feito para sobreviver à perda de uma máquina roda três ou
cinco membros, para uma maioria sobreviver a uma ou duas falhas. Mais membros não substituem um backup,
porque um `kubectl delete` é replicado para todos eles com a mesma fidelidade.

O ConfigMap `before-backup` foi criado logo antes do snapshot, então o snapshot o guarda. O snapshot é um
arquivo de 2,1 MB com 453 chaves, e o último comando o copiou **para fora da máquina**. Um backup no disco
do nó que ele protege se perde com esse nó.

## A restauração

Agora o ConfigMap é apagado, e o cluster volta ao snapshot:

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

Quatro passos, e cada um é um arquivo sendo movido:

1. **Pare o control plane** tirando os manifestos do diretório que o kubelet observa. Restaurar por baixo
   de um etcd rodando corromperia os dois.
2. **Restaure o snapshot num diretório novo.** O `etcdutl` escreve um diretório de dados novo, com o nome
   e o endereço de par deste membro, em vez de sobrescrever o antigo; o antigo fica como caminho de volta.
3. **Aponte o pod do etcd para ele.** O manifesto monta um diretório do nó como dados; o `sed` muda esse
   caminho, e o `grep` confirma a única linha que ele mudou.
4. **Inicie o control plane** devolvendo os manifestos.

`present`: o ConfigMap apagado voltou, e os nós estão como estavam. Todo o resto também, até o segundo em
que o snapshot foi tirado, **e tudo o que foi escrito depois desse segundo sumiu**. Um backup diário
significa até um dia de mudanças perdido, e o intervalo entre backups é o número a combinar antes do dia
em que ele for necessário.

Uma restauração que ninguém ensaiou é a metade fraca do backup. Os comandos acima levam minutos num
cluster feito para isso, e é ali o lugar de descobrir que os caminhos dos certificados são outros ou que
o `etcdutl` não está instalado.
