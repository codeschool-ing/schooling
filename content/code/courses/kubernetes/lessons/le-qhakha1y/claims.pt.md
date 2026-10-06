---
title: O claim, o volume e a classe
version: 1
---

**Uma aplicação não deveria precisar saber que disco recebe.** Num laptop é um diretório, numa nuvem
um dispositivo de bloco, em outra um sistema de arquivos de rede. O Kubernetes mantém isso fora do pod
com três objetos: o pod nomeia um PersistentVolumeClaim, o claim é ligado a um PersistentVolume, e uma
StorageClass criou o volume.

A classe vem primeiro, porque um cluster já tem uma antes de alguém pedir:

```
ana@laptop:~/shop$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  64s
ana@laptop:~/shop$ kubectl get storageclass standard -o jsonpath="{.provisioner} {.reclaimPolicy} {.volumeBindingMode}{\"\\n\"}"
rancher.io/local-path Delete WaitForFirstConsumer
```

O kind traz uma classe, `standard`, marcada como padrão, cujo provisioner é o local-path provisioner:
cada volume que ele cria é um diretório num nó. A classe padrão de uma nuvem nomeia o serviço de discos
da nuvem, e o resto desta seção se lê exatamente igual lá.

## Pedindo

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

O claim pede um gibibyte que um nó de cada vez pode montar para escrita, `ReadWriteOnce`. Ele não
nomeia classe, então recebe a padrão.

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

**`Pending`, e de propósito.** `volumeBindingMode: WaitForFirstConsumer` diz ao provisioner para
esperar um pod que use o claim, porque para armazenamento que vive num nó ou numa zona, o volume
precisa ser criado onde esse pod vai rodar. Criá-lo antes deixaria o scheduler achar depois para o pod
um nó que o volume não alcança.

Um pod que monta o claim pelo nome:

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

O pod chegou, o scheduler escolheu `shop-worker`, e o provisioner criou um PersistentVolume lá e o
ligou ao claim. **O volume registra o seu nó**, então todo pod que usar este claim daqui em diante vai
para `shop-worker`. Esse é o preço do armazenamento local num nó. Um disco de nuvem registra uma zona
em vez de um nó, que é uma versão mais frouxa do mesmo laço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Da esquerda para a direita: o pod writer monta o claim orders. O PersistentVolumeClaim orders pede 1Gi, ReadWriteOnce. Ele está ligado a um PersistentVolume, pvc-641c…, 1Gi, que registra o nó shop-worker. Abaixo do claim, a StorageClass standard, provisioner rancher.io/local-path, criou o volume quando o claim pediu. O volume é um diretório no nó.\"><defs><marker id=\"pv-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pv-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"pv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"pv-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Pod writer</text><text x=\"90.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">mountPath: /data</text><rect x=\"220\" y=\"40\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PVC orders</text><text x=\"310.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1Gi · ReadWriteOnce</text><rect x=\"460\" y=\"40\" width=\"240\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PV pvc-641c…</text><text x=\"580.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1Gi · Delete</text><text x=\"580.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">node: shop-worker</text><rect x=\"220\" y=\"160\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">StorageClass standard</text><text x=\"310.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rancher.io/local-path</text><rect x=\"490\" y=\"160\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um diretório em shop-worker</text><path d=\"M162 68 L218 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pv-ah-paper-dim)\"></path><text x=\"190\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pede</text><path d=\"M402 68 L458 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pv-ah-phosphor)\" marker-start=\"url(#pv-ah-phosphor)\"></path><text x=\"430\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">ligado</text><path d=\"M402 188 L430 188 L430 120 L540 120 L540 98\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#pv-ah-amber)\"></path><text x=\"484\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">criou</text><path d=\"M580 98 L580 158\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "O pod só conhece o nome do claim. Qual disco, qual nó e qual provedor são assunto do claim e da classe."}
```

| objeto | escrito por | diz |
|---|---|---|
| PersistentVolumeClaim | quem escreve a aplicação | quanto, e como vai ser montado |
| PersistentVolume | o provisioner, ou um operador à mão | onde o armazenamento de fato está |
| StorageClass | o operador do cluster | como criar um volume, e o que acontece com ele depois |
