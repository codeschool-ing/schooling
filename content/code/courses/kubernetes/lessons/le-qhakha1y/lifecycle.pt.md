---
title: O que sobrevive a quê
version: 1
---

O writer acrescenta `order-2001` a um arquivo no claim cada vez que sobe. Apague o pod e crie de novo:

```
ana@laptop:~/shop$ kubectl delete pod writer
pod "writer" deleted from default namespace
ana@laptop:~/shop$ kubectl apply -f writer.yaml
pod/writer created
ana@laptop:~/shop$ kubectl exec writer -- cat /data/orders.txt
order-2001
order-2001
```

**Duas linhas: o segundo pod achou os dados do primeiro.** O claim sobreviveu ao pod, e o pod novo foi
para `shop-worker`, onde o volume está. Essa é a propriedade para a qual todo o arranjo existe, e ela
vale para todo jeito que um pod tem de sumir, um rollout inclusive.

## Apagando o claim

O que acontece com os dados quando o próprio claim é apagado é a `reclaimPolicy` da StorageClass, e a
classe padrão dizia `Delete`:

```
ana@laptop:~/shop$ kubectl delete pod writer
pod "writer" deleted from default namespace
ana@laptop:~/shop$ kubectl delete pvc orders
persistentvolumeclaim "orders" deleted from default namespace
ana@laptop:~/shop$ kubectl get pv
No resources found
```

**O volume, e o diretório com `order-2001` dentro, sumiram.** Com `Delete`, remover um claim remove o
armazenamento dele, num laptop e numa nuvem do mesmo jeito, onde isso apaga o disco. É cômodo para
ambientes de rascunho e um desastre para um banco cujo claim alguém apagou por engano.

`Retain` é a outra política. Uma segunda classe, o mesmo provisioner, uma linha diferente:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: keep
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

Um claim chamado `ledger` nessa classe, um pod para criar o volume, e depois as mesmas duas remoções:

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

**O volume continua lá, `Released`**: o claim dele sumiu, e os dados dentro estão intactos. Ele não
vai ser ligado a um claim novo sozinho, porque ainda lembra do antigo; um operador decide o que
acontece depois, e esse é o ponto. Recuperá-lo quer dizer limpar essa memória, o `claimRef`, para que
um claim novo possa se ligar a ele, ou copiar os dados para fora. Apagá-lo, quando ninguém mais
precisar, é um `kubectl delete pv` deliberado, e com `Retain` o disco por trás dele numa nuvem fica até
alguém apagar esse também.

| `reclaimPolicy` | o claim é apagado | certo para |
|---|---|---|
| `Delete` | o volume e o armazenamento são removidos | caches, ambientes de teste, qualquer coisa fácil de refazer |
| `Retain` | o volume fica, `Released`, dados intactos | bancos e qualquer coisa que ninguém consegue refazer |

Um claim apagado não é o único risco aos dados, e nada disto é backup. A lição 28 é sobre bancos no
cluster e o que os protege.
