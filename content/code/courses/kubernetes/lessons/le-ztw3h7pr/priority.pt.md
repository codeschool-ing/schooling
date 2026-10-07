---
title: Quando o cluster está cheio, quem sai primeiro
version: 1
---

A lição 19 deixou um pod `Pending` porque nenhum nó tinha espaço, e a mensagem do scheduler terminava
com "preemption: … No preemption victims found". **Preempção é o scheduler abrindo espaço para um pod
despejando pods de prioridade menor**, e a prioridade é definida por uma PriorityClass:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: checkout
value: 100000
description: "The path that takes customers' money."
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch
value: 1000
description: "Reports and other work that can wait."
```

```
ana@laptop:~/shop$ kubectl apply -f priorities.yaml
priorityclass.scheduling.k8s.io/checkout created
priorityclass.scheduling.k8s.io/batch created
ana@laptop:~/shop$ kubectl get priorityclasses
NAME                      VALUE        GLOBAL-DEFAULT   AGE   PREEMPTIONPOLICY
batch                     1000         false            1s    PreemptLowerPriority
checkout                  100000       false            1s    PreemptLowerPriority
system-cluster-critical   2000000000   false            28s   PreemptLowerPriority
system-node-critical      2000001000   false            28s   PreemptLowerPriority
```

Uma classe é um nome para um número; o maior vence. As duas classes `system-` vêm com o cluster, para
os componentes sem os quais ele não roda, e ficam muito acima de qualquer coisa que uma aplicação
deveria usar.

O trabalho de batch chega primeiro e enche o cluster: quatro cópias com 1700m de CPU cada, duas por
worker, deixando cada nó com algumas centenas de milicores livres.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch
spec:
  replicas: 4
  selector:
    matchLabels:
      app: batch
  template:
    metadata:
      labels:
        app: batch
    spec:
      priorityClassName: batch
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1700m"
```

```
ana@laptop:~/shop$ kubectl apply -f batch.yaml
deployment.apps/batch created
ana@laptop:~/shop$ kubectl get pods -l app=batch -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
batch-777ccd8566-5bqqk   1/1     Running   0          0s    10.244.1.7   shop-worker2   <none>           <none>
batch-777ccd8566-d8gwj   1/1     Running   0          0s    10.244.2.7   shop-worker    <none>           <none>
batch-777ccd8566-rkg2t   1/1     Running   0          0s    10.244.2.6   shop-worker    <none>           <none>
batch-777ccd8566-tdrjj   1/1     Running   0          0s    10.244.1.8   shop-worker2   <none>           <none>
```

Depois o checkout, duas cópias do mesmo tamanho e cem vezes a prioridade:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
spec:
  replicas: 2
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
    spec:
      priorityClassName: checkout
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1700m"
```

```
ana@laptop:~/shop$ kubectl apply -f checkout.yaml
deployment.apps/checkout created
ana@laptop:~/shop$ kubectl get pods -l "app in (batch,checkout)" -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,STATUS:.status.phase,NODE:.spec.nodeName
NAME                       PRIORITY   STATUS    NODE
batch-777ccd8566-9cv8t     1000       Pending   <none>
batch-777ccd8566-d8gwj     1000       Running   shop-worker
batch-777ccd8566-lshzm     1000       Pending   <none>
batch-777ccd8566-tdrjj     1000       Running   shop-worker2
checkout-6cfcc6c86-mk8tg   100000     Running   shop-worker2
checkout-6cfcc6c86-nftr2   100000     Running   shop-worker
```

**As duas cópias de checkout estão rodando, e duas cópias de batch viraram `Pending`.** Nenhum nó tinha
1700m livres, então para cada pod de checkout o scheduler procurou pods de prioridade menor cuja remoção
abrisse espaço, despejou um pod de batch em cada nó, e pôs o checkout ali. O Deployment de batch
substituiu os dois pods, e os substitutos esperam, porque não sobrou nada de prioridade menor para
despejar. Os eventos citam as vítimas:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=Preempted -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message
OBJECT                   MESSAGE
batch-777ccd8566-5bqqk   Preempted by pod c8d36575-6d91-47f7-84b4-26934b3a478d on node shop-worker2
batch-777ccd8566-rkg2t   Preempted by pod d6296d9a-5d48-4906-8dde-c7c78b5db526 on node shop-worker
```

A preempção respeita PodDisruptionBudgets quando pode, mas quebra um se nada mais liberar o espaço; um
orçamento protege contra manutenção, não contra um pod mais importante.

**Três cuidados.** Os pods de um Deployment só são tão importantes quanto a classe diz, então um
cluster em que toda equipe se dá a classe mais alta não tem prioridade nenhuma; administradores
costumam restringir quem pode usar as classes altas. Uma classe com `preemptionPolicy: Never` entra na
fila na frente das outras mas não despeja ninguém, o que serve para trabalho urgente que não vale matar
nada. E a preempção libera espaço do jeito que o scheduler conta, em requests, então ela só é tão boa
quanto os requests forem honestos.
