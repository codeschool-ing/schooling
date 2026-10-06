---
title: Tudo no cluster é um objeto
version: 1
---

**A primeira imagem costuma ser a de que o Kubernetes roda containers. Ele roda, no fim das contas,
mas aquilo com que você conversa é um depósito de registros.** Cada nó, cada cópia da loja, cada regra
sobre quem pode fazer o quê é um objeto guardado pelo API server, com um tipo e um nome, e quase todo
o resto do cluster é um programa que lê esses objetos e age sobre eles. Aprender Kubernetes é, na
maior parte, aprender os tipos.

O cluster do laptop, da lição 5, tem três nós, e cada nó é ele mesmo um objeto:

```
ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   32s   v1.37.0
shop-worker          Ready    <none>          17s   v1.37.0
shop-worker2         Ready    <none>          17s   v1.37.0
```

## Os tipos, listados pelo próprio cluster

O API server sabe dizer quais tipos conhece:

```
ana@laptop:~/shop$ kubectl api-resources --no-headers | wc -l
71
ana@laptop:~/shop$ kubectl api-resources | head -n 12
NAME                                SHORTNAMES   APIVERSION                        NAMESPACED   KIND
bindings                                         v1                                true         Binding
componentstatuses                   cs           v1                                false        ComponentStatus
configmaps                          cm           v1                                true         ConfigMap
endpoints                           ep           v1                                true         Endpoints
events                              ev           v1                                true         Event
limitranges                         limits       v1                                true         LimitRange
namespaces                          ns           v1                                false        Namespace
nodes                               no           v1                                false        Node
persistentvolumeclaims              pvc          v1                                true         PersistentVolumeClaim
persistentvolumes                   pv           v1                                false        PersistentVolume
pods                                po           v1                                true         Pod
```

**Setenta e um tipos**, e este cluster não tem nada instalado além do que o kind põe. Cada linha dá
o nome que você digita, um nome curto (`po` para `pods`), o grupo e a versão da API a que ele pertence
e se um objeto daquele tipo vive dentro de um namespace ou pertence ao cluster inteiro: um pod está
sempre num namespace, um nó nunca está. A lição 43 acrescenta um tipo seu a esta lista.

## Um comando, cinco objetos

A Ana pede três cópias da loja e depois lista três tipos de uma vez:

```
ana@laptop:~/shop$ kubectl create deployment web --image=shop:1.0 --replicas=3
deployment.apps/web created
ana@laptop:~/shop$ kubectl get deployments,replicasets,pods
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   3/3     3            3           2s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-768c88b7c7   3         3         3       2s

NAME                       READY   STATUS    RESTARTS   AGE
pod/web-768c88b7c7-2cfcg   1/1     Running   0          1s
pod/web-768c88b7c7-rwz26   1/1     Running   0          1s
pod/web-768c88b7c7-vdp2x   1/1     Running   0          1s
```

Ela criou um objeto, um Deployment chamado `web`. **O cluster fez mais quatro**: um ReplicaSet, cujo
nome acrescenta um hash do modelo de pod, `768c88b7c7`, e três Pods, cujos nomes acrescentam cinco
caracteres aleatórios a ele. Ninguém digitou esses nomes. Dois controladores fizeram o trabalho: o
controlador de deployments criou o ReplicaSet, e o controlador de ReplicaSets criou os pods. A lição
10 desmonta essa corrente.

## O spec é o que você pediu, o status é o que é verdade

Todo objeto que faz alguma coisa tem duas metades, e o cluster as mantém separadas de propósito.

```
ana@laptop:~/shop$ kubectl get deployment web -o custom-columns=NAME:.metadata.name,WANTED:.spec.replicas,READY:.status.readyReplicas,IMAGE:.spec.template.spec.containers[0].image
NAME   WANTED   READY   IMAGE
web    3        3       shop:1.0
```

`WANTED` lê `.spec.replicas`, que a Ana definiu. `READY` lê `.status.readyReplicas`, que um
controlador escreveu depois de contar. **Quando as duas concordam, o laço da lição 1 não tem nada a
fazer**; quando diferem, a diferença é o trabalho. Eis um dos pods, as primeiras linhas do objeto
como o API server o guarda:

```
ana@laptop:~/shop$ POD=$(kubectl get pods -l app=web -o name | head -n 1); echo $POD
pod/web-768c88b7c7-2cfcg
ana@laptop:~/shop$ kubectl get $POD -o yaml | head -n 24
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2026-10-06T16:26:39Z"
  generateName: web-768c88b7c7-
  generation: 1
  labels:
    app: web
    pod-template-hash: 768c88b7c7
  name: web-768c88b7c7-2cfcg
  namespace: default
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: web-768c88b7c7
    uid: c1eb7232-604f-41c3-b768-1fffb6b37199
  resourceVersion: "658"
  uid: 5b9a9a38-ad25-469f-8f2d-d464e8c7b0da
spec:
  containers:
  - image: shop:1.0
    imagePullPolicy: IfNotPresent
```

`metadata` diz o que o objeto é: o `name`, o `namespace`, os `labels` e uma entrada em
`ownerReferences` que nomeia o ReplicaSet que o criou, que é como a corrente da seção anterior fica
registrada. O `spec` começa logo abaixo, com o container e a imagem. A metade do status está mais
abaixo no mesmo documento, escrita pelo cluster e não pela Ana:

```
ana@laptop:~/shop$ kubectl get $POD -o custom-columns=PHASE:.status.phase,IP:.status.podIP,NODE:.spec.nodeName
PHASE     IP           NODE
Running   10.244.1.2   shop-worker
```

`Running` é a fase, `10.244.1.2` o endereço que o pod recebeu e `shop-worker` o nó em que o
escalonador o colocou. Nenhum dos três estava no que a Ana pediu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um objeto desenhado como quatro partes empilhadas. apiVersion e kind dizem de que tipo ele é. metadata diz qual ele é: nome, namespace, labels, dono. spec, escrito por você, diz o que deveria ser verdade: três réplicas de shop:1.0. status, escrito pelo cluster, diz o que é verdade: três prontas. Um controlador compara o spec com o status.\"><defs><marker id=\"an-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">apiVersion · kind</text><text x=\"440\" y=\"43\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">apps/v1 · Deployment</text><text x=\"480\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qual tipo</text><rect x=\"40\" y=\"76\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">metadata</text><text x=\"440\" y=\"99\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">name: web · labels: app=web</text><text x=\"480\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qual objeto</text><rect x=\"40\" y=\"132\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">spec</text><text x=\"440\" y=\"155\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replicas: 3 · image: shop:1.0</text><text x=\"480\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que deveria ser verdade</text><rect x=\"40\" y=\"188\" width=\"420\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">status</text><text x=\"440\" y=\"211\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">readyReplicas: 3</text><text x=\"480\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que é verdade</text><text x=\"480\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">escrito por você</text><text x=\"480\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">escrito pelo cluster</text><path d=\"M30 143 L22 143 L22 199 L30 199\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um controlador compara os dois</text></svg>", "caption": "O spec e o status ficam separados para que a diferença entre eles possa ser lida, e tratada."}
```

## A API documenta a si mesma

Cada campo tem uma descrição que o API server serve, então a referência nunca está a mais de um
comando de distância:

```
ana@laptop:~/shop$ kubectl explain deployment.spec.replicas
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: replicas <integer>


DESCRIPTION:
    Number of desired pods. This is a pointer to distinguish between explicit
    zero and not specified. Defaults to 1.
    
```

O `kubectl explain` percorre qualquer caminho de um tipo, `deployment.spec.template.spec.containers`
tão facilmente quanto este, e a resposta vem da versão do Kubernetes que o cluster de fato roda.
