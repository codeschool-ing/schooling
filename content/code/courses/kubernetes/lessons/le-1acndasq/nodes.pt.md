---
title: Escolhendo nós pelos rótulos
version: 1
---

Toda regra desta lição trabalha com rótulos, os mesmos pares de chave e valor que os Services usam para
achar pods. **Nós também carregam rótulos**: alguns postos pelo kubelet (`kubernetes.io/hostname`, o
sistema operacional, a arquitetura), alguns por uma nuvem (a zona, o tipo de máquina), e alguns por
quem opera o cluster. Aqui um worker é rotulado como tendo discos rápidos:

```
ana@laptop:~/shop$ kubectl label node shop-worker2 disk=ssd
node/shop-worker2 labeled
ana@laptop:~/shop$ kubectl get nodes -L disk
NAME                 STATUS   ROLES           AGE   VERSION   DISK
shop-control-plane   Ready    control-plane   34s   v1.37.0   
shop-worker          Ready    <none>          18s   v1.37.0   
shop-worker2         Ready    <none>          18s   v1.37.0   ssd
```

## Uma exigência: `nodeSelector`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: search
spec:
  replicas: 3
  selector:
    matchLabels:
      app: search
  template:
    metadata:
      labels:
        app: search
    spec:
      nodeSelector:
        disk: ssd
      containers:
      - name: shop
        image: shop:1.0
```

**`nodeSelector` é a regra mais simples que existe: todo rótulo listado precisa estar no nó, ou o pod
não vai para lá.**

```
ana@laptop:~/shop$ kubectl apply -f on-ssd.yaml
deployment.apps/search created
ana@laptop:~/shop$ kubectl get pods -l app=search -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
search-5f6cb89597-6djn8   1/1     Running   0          1s    10.244.1.3   shop-worker2   <none>           <none>
search-5f6cb89597-fc5xp   1/1     Running   0          1s    10.244.1.4   shop-worker2   <none>           <none>
search-5f6cb89597-zwngc   1/1     Running   0          1s    10.244.1.5   shop-worker2   <none>           <none>
```

As três cópias em `shop-worker2`, o único nó com `disk=ssd`, mesmo com `shop-worker` parado. Esse é o
ponto e o risco de uma exigência: o scheduler a obedece mesmo quando ela deixa um nó vazio e põe todas
as cópias numa máquina só.

## Uma exigência que ninguém atende

Mude o seletor para um rótulo que nenhum nó tem:

```
ana@laptop:~/shop$ kubectl patch deployment search -p '{"spec":{"template":{"spec":{"nodeSelector":{"disk":"nvme"}}}}}'
deployment.apps/search patched
ana@laptop:~/shop$ kubectl get pods -l app=search
NAME                      READY   STATUS    RESTARTS   AGE
search-5f6cb89597-6djn8   1/1     Running   0          9s
search-5f6cb89597-fc5xp   1/1     Running   0          9s
search-5f6cb89597-zwngc   1/1     Running   0          9s
search-646fd449f9-zs8c5   0/1     Pending   0          8s
```

**O pod novo espera em `Pending`, e os três antigos continuam rodando.** O rollout do Deployment cria
um pod novo antes de remover um antigo, então um template que ninguém consegue alocar para o rollout
no primeiro passo, e a versão antiga continua atendendo. A lição 35 é sobre esse comportamento. O
evento do scheduler diz o que falta:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

"Didn't match Pod's node affinity/selector" nos dois workers, e o nó control-plane excluído pelo taint
dele, que a lição 30 explica. Um erro de digitação num rótulo basta para produzir exatamente isto.

## Uma preferência

A afinidade de nó diz as mesmas coisas numa forma mais longa, e acrescenta o que um seletor não
consegue: operadores como `In`, `NotIn` e `Exists`, e preferências.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
spec:
  replicas: 4
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: disk
                operator: In
                values: ["nvme", "ssd"]
      containers:
      - name: shop
        image: shop:1.0
```

`preferredDuringSchedulingIgnoredDuringExecution` é um desejo com um peso de 1 a 100: nós que casam
ganham pontos a mais na pontuação do scheduler, e nós que não casam continuam permitidos.

```
ana@laptop:~/shop$ kubectl apply -f prefer-ssd.yaml
deployment.apps/cache created
ana@laptop:~/shop$ kubectl get pods -l app=cache -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
cache-66f4c4dfc4-dqrf2   1/1     Running   0          1s    10.244.1.6   shop-worker2   <none>           <none>
cache-66f4c4dfc4-gx86n   1/1     Running   0          1s    10.244.1.9   shop-worker2   <none>           <none>
cache-66f4c4dfc4-hml4x   1/1     Running   0          1s    10.244.1.8   shop-worker2   <none>           <none>
cache-66f4c4dfc4-zjvdn   1/1     Running   0          1s    10.244.1.7   shop-worker2   <none>           <none>
```

As quatro em `shop-worker2`. **Um peso de 100 é um desejo forte**, o bastante aqui para vencer o
hábito do próprio scheduler de espalhar pods, porque o nó tinha espaço para as quatro. Se ele
estivesse cheio, o resto teria ido para `shop-worker`, o que uma exigência nunca permitiria. Os nomes
longos dizem mais uma coisa: `IgnoredDuringExecution` quer dizer que as regras são conferidas quando
um pod é alocado e nunca mais, então tirar o rótulo depois não move nada.

| regra | tipo | se nenhum nó casa |
|---|---|---|
| `nodeSelector` | exigência | o pod fica `Pending` |
| afinidade de nó `requiredDuringScheduling…` | exigência, com operadores | o pod fica `Pending` |
| afinidade de nó `preferredDuringScheduling…` | preferência, com peso | o pod vai para outro lugar |
