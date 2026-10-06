---
title: As palavras do cluster
version: 1
---

O resto deste curso usa cerca de uma dúzia de palavras sem parar para defini-las, então elas são
definidas aqui, uma vez, e cada uma aponta para a lição que a aprofunda. **A ideia a guardar é que a
maioria delas nomeia um tipo de objeto**, e as outras nomeiam as máquinas e os programas que agem
sobre esses objetos.

| palavra | o que é | em profundidade |
|---|---|---|
| cluster | um conjunto de máquinas operado como uma só, com uma API | lição 4 |
| nó | uma máquina do cluster, real ou virtual, rodando um kubelet | lição 4 |
| plano de controle | os programas que guardam objetos e decidem: API server, etcd, escalonador, controladores | lição 4 |
| pod | um ou mais containers que rodam juntos num nó e compartilham um endereço | lição 9 |
| controlador | um programa que observa um tipo e faz o mundo bater com o spec dele | lição 44 |
| Deployment, ReplicaSet | os objetos que mantêm um número de pods idênticos rodando | lição 10 |
| Service | um endereço estável na frente de um conjunto de pods que muda | lição 15 |
| namespace | um escopo de nomes para objetos, usado para dividir um cluster entre equipes | lição 20 |
| label | uma chave e um valor num objeto, escolhidos por você | esta seção |
| seletor | uma pergunta sobre labels, que escolhe os objetos que a respondem | esta seção |

## Labels: como um objeto encontra outro

Um pod não pertence a um ReplicaSet por estar listado dentro dele. **Pertence porque carrega os
labels que o seletor do ReplicaSet pede.** O `kubectl create deployment web` deu a cada pod o label
`app=web`, e o ReplicaSet acrescentou `pod-template-hash`:

```
ana@laptop:~/shop$ kubectl get pods --show-labels
NAME                   READY   STATUS    RESTARTS   AGE   LABELS
web-768c88b7c7-2cfcg   1/1     Running   0          1s    app=web,pod-template-hash=768c88b7c7
web-768c88b7c7-rwz26   1/1     Running   0          1s    app=web,pod-template-hash=768c88b7c7
web-768c88b7c7-vdp2x   1/1     Running   0          1s    app=web,pod-template-hash=768c88b7c7
```

Os mesmos labels respondem às suas perguntas. `-l app=web` é um seletor, e `-o wide` acrescenta o
endereço e o nó de cada pod:

```
ana@laptop:~/shop$ kubectl get pods -l app=web -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
web-768c88b7c7-2cfcg   1/1     Running   0          1s    10.244.1.2   shop-worker    <none>           <none>
web-768c88b7c7-rwz26   1/1     Running   0          1s    10.244.2.3   shop-worker2   <none>           <none>
web-768c88b7c7-vdp2x   1/1     Running   0          1s    10.244.2.2   shop-worker2   <none>           <none>
```

O escalonador pôs uma cópia em `shop-worker` e duas em `shop-worker2`, e ninguém pediu essa divisão.
A lição 29 mostra como pedir. Escolher por label em vez de por nome é o que deixa o cluster inteiro
continuar funcionando enquanto pods vêm e vão: um Service, um ReplicaSet e uma política de rede
encontram os seus pods com um seletor, então um pod substituto com os labels certos é encontrado no
momento em que passa a existir.

## Namespaces: escopos, não lugares

Um cluster novo já tem cinco:

```
ana@laptop:~/shop$ kubectl get namespaces
NAME                 STATUS   AGE
default              Active   35s
kube-node-lease      Active   35s
kube-public          Active   35s
kube-system          Active   35s
local-path-storage   Active   31s
```

`default` é onde os objetos da Ana foram parar porque ela não indicou outro. `kube-system` guarda o
maquinário do próprio cluster, e listá-lo mostra que **o plano de controle e os agentes dos nós
também rodam como pods**:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system
NAME                                         READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-9fw4r                     1/1     Running   0          25s
coredns-559f6c778d-v6p5k                     1/1     Running   0          25s
etcd-shop-control-plane                      1/1     Running   0          32s
kindnet-mfvl8                                1/1     Running   0          20s
kindnet-q7jtj                                1/1     Running   0          25s
kindnet-zb5wv                                1/1     Running   0          20s
kube-apiserver-shop-control-plane            1/1     Running   0          32s
kube-controller-manager-shop-control-plane   1/1     Running   0          32s
kube-proxy-2mpqg                             1/1     Running   0          20s
kube-proxy-tqhf2                             1/1     Running   0          25s
kube-proxy-wrwp9                             1/1     Running   0          20s
kube-scheduler-shop-control-plane            1/1     Running   0          34s
```

Há um `kube-proxy` e um `kindnet` por nó, três de cada, e um de cada componente do plano de controle,
em `shop-control-plane`. Um namespace agrupa esses pods pelo propósito e não diz nada sobre onde eles
rodam: os pods de `kube-system` estão espalhados pelos três nós, lado a lado com os da Ana.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um cluster com três nós lado a lado. Cada nó tem pods, e cada pod tem um container. Os pods da loja, na cor do namespace default, estão em dois nós diferentes, e etcd e kube-proxy, tracejados para o namespace kube-system, estão nos três.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cluster</text><rect x=\"150\" y=\"44\" width=\"170\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-control-plane</text><rect x=\"164\" y=\"90\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"197\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">etcd</text><rect x=\"164\" y=\"218\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"197\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"335\" y=\"44\" width=\"170\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"349\" y=\"150\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"382\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">web</text><rect x=\"349\" y=\"218\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"382\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"520\" y=\"44\" width=\"170\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"534\" y=\"150\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">web</text><rect x=\"608\" y=\"150\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"641\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">web</text><rect x=\"534\" y=\"218\" width=\"66\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"567\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-proxy</text><text x=\"24\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">namespace</text><text x=\"24\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">default</text><text x=\"24\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace</text><text x=\"24\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kube-system</text></svg>", "caption": "Nós, pods e containers ficam uns dentro dos outros. Um namespace não: ele atravessa os nós e agrupa objetos pelo propósito.", "same": ["cluster", "namespace"]}
```
