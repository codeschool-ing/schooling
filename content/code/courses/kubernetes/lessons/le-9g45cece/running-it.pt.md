---
title: Criar, mudar, quebrar, apagar
version: 1
---

Com o controller rodando num segundo terminal e escrevendo em `controller.log`, o Backup da lição 43 é
criado de novo:

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

**Numa volta, um CronJob apareceu, cujo dono é o Backup.** O controller registrou o que fez, e a
referência de dono cita o Backup. O CronJob pode ser rodado sob demanda para ver o que faz:

```
ana@laptop:~/shop/backup-controller$ kubectl create job manual --from=cronjob/backup-orders-nightly
job.batch/manual created
ana@laptop:~/shop/backup-controller$ kubectl logs job/manual
would dump orders and keep 7 copies
```

O pod do Job imprimiu o que um backup de verdade faria, com `keep` no padrão 7 do schema.

## Uma mudança no que se quer

```
ana@laptop:~/shop/backup-controller$ kubectl patch backup orders-nightly --type=merge -p '{"spec":{"schedule":"30 2 * * *"}}'
backup.shop.example.test/orders-nightly patched
ana@laptop:~/shop/backup-controller$ tail -n 1 controller.log
2026/10/06 18:14:05 orders-nightly: schedule "0 3 * * *" -> "30 2 * * *"
ana@laptop:~/shop/backup-controller$ kubectl get cronjobs
NAME                    SCHEDULE     TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
backup-orders-nightly   30 2 * * *   <none>     False     0        <none>          13s
```

O horário foi mudado no Backup, não no CronJob, e em cinco segundos o controller viu a diferença e
atualizou o CronJob. **As pessoas editam o objeto que entendem, e o controller o traduz** nos objetos que
o Kubernetes entende.

## Uma mudança no que existe

Alguém apaga o CronJob à mão:

```
ana@laptop:~/shop/backup-controller$ kubectl delete cronjob backup-orders-nightly
cronjob.batch "backup-orders-nightly" deleted from default namespace
ana@laptop:~/shop/backup-controller$ tail -n 1 controller.log
2026/10/06 18:14:10 orders-nightly: created cronjob backup-orders-nightly (30 2 * * *)
ana@laptop:~/shop/backup-controller$ kubectl get cronjobs
NAME                    SCHEDULE     TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
backup-orders-nightly   30 2 * * *   <none>     False     0        <none>          5s
```

Recriado na volta seguinte, com o horário atual. O controller não percebeu uma remoção; percebeu, como
faz em toda volta, que o CronJob que ele espera não existia. Essa é a diferença entre reagir a eventos e
reconciliar estado, e é por isso que o mesmo código cuida de uma primeira criação, de uma remoção por
engano e de um reinício do próprio controller.

## Apagando o Backup

```
ana@laptop:~/shop/backup-controller$ kubectl delete backup orders-nightly
backup.shop.example.test "orders-nightly" deleted from default namespace
ana@laptop:~/shop/backup-controller$ kubectl get cronjobs,backups
No resources found in default namespace.
```

O Backup e o CronJob dele sumiram, e o controller não tem código para remoção. **Quem fez foi a
referência de dono**: o coletor de lixo do Kubernetes apaga objetos cujo dono não existe mais, então a
limpeza é declarada quando o objeto é criado, e não escrita como um caminho à parte que alguém pode
esquecer.
