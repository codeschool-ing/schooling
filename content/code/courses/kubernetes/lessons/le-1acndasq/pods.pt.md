---
title: Escolhendo nós pelos pods que já estão neles
version: 1
---

Regras de nó olham o nó. **Afinidade e anti-afinidade de pod olham os pods que já rodam ali**, que é
como dizer "não um ao lado do outro" e "ao lado daquele".

## Separados: anti-afinidade

Três cópias da loja só são três cópias se estiverem em máquinas diferentes; três num nó só morrem
juntas.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: shop
            topologyKey: kubernetes.io/hostname
      containers:
      - name: shop
        image: shop:1.0
```

Leia a regra como uma frase: não ponha este pod num domínio `topologyKey` que já tenha um pod que case
com `app: shop`. Com `kubernetes.io/hostname` como chave, o domínio é um único nó.

```
ana@laptop:~/shop$ kubectl apply -f spread-out.yaml
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get pods -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES
shop-6c485b4895-2xds4   0/1     Pending   0          10s   <none>        <none>         <none>           <none>
shop-6c485b4895-ctzx7   1/1     Running   0          10s   10.244.2.3    shop-worker    <none>           <none>
shop-6c485b4895-x2l85   1/1     Running   0          10s   10.244.1.10   shop-worker2   <none>           <none>
ana@laptop:~/shop$ kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 node(s) didn't match pod anti-affinity rules. preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
```

**Uma cópia em cada worker, e a terceira `Pending`.** Dois nós aceitam pods comuns, a regra permite uma
cópia em cada, e ela é uma exigência, então a terceira espera em vez de dobrar. Esse é o comportamento
pedido e uma armadilha ao mesmo tempo: um cluster com menos nós do que réplicas não consegue rodar o
Deployment inteiro. A forma preferida, `preferredDuringSchedulingIgnoredDuringExecution`, espalha
quando consegue e dobra quando precisa, e as topology spread constraints da lição 31 dizem a mesma
coisa com um número para o quanto de desequilíbrio é aceitável.

Com `topology.kubernetes.io/zone` como chave, a mesma regra põe cada cópia numa zona diferente, que é
o que sobrevive à perda de um data center.

## Juntos: afinidade

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidekick
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sidekick
  template:
    metadata:
      labels:
        app: sidekick
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: shop
            topologyKey: kubernetes.io/hostname
      containers:
      - name: box
        image: busybox:1.37
        command: ["sleep", "3600"]
```

`podAffinity` é a frase oposta: ponha este pod num domínio que já tenha um pod rotulado `app: shop`.

```
ana@laptop:~/shop$ kubectl apply -f next-to-shop.yaml
deployment.apps/sidekick created
ana@laptop:~/shop$ kubectl get pods -l "app in (shop,sidekick)" -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
NAME                        STATUS    NODE
shop-6c485b4895-2xds4       Pending   <none>
shop-6c485b4895-ctzx7       Running   shop-worker
shop-6c485b4895-x2l85       Running   shop-worker2
sidekick-64c4f9b8f4-lscdb   Running   shop-worker2
sidekick-64c4f9b8f4-tz5jf   Running   shop-worker
```

**Cada sidekick caiu num nó que tem um pod da loja.** Nada prendeu o primeiro sidekick a uma cópia em
particular; a regra só pede um nó que tenha uma. Um ajudante que precisa falar com o parceiro por
localhost pertence ao mesmo pod, como um segundo container. Afinidade é para coisas que só ganham por
estar perto, como um cache ao lado do serviço que o lê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três nós. shop-control-plane tem um taint e não recebe pods comuns. shop-worker roda um pod da loja e um sidekick. shop-worker2 roda um pod da loja e um sidekick. O terceiro pod da loja fica fora de todos os nós, Pending, porque a anti-afinidade proíbe um segundo pod da loja num nó que já tem um.\"><defs></defs><rect x=\"20\" y=\"20\" width=\"165\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"102\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-control-plane</text><text x=\"102\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">taint: nada de pods comuns</text><rect x=\"200\" y=\"20\" width=\"165\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker</text><rect x=\"215\" y=\"56\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"282.5\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"282.5\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop</text><rect x=\"215\" y=\"112\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"282.5\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sidekick</text><text x=\"282.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=sidekick</text><rect x=\"380\" y=\"20\" width=\"165\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"395\" y=\"56\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"462.5\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"462.5\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop</text><rect x=\"395\" y=\"112\" width=\"135\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462.5\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sidekick</text><text x=\"462.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=sidekick</text><rect x=\"570\" y=\"56\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"635.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop</text><text x=\"635\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">Pending</text><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Pending: todo nó já tem um</text></svg>", "caption": "A anti-afinidade espalhou a loja, uma cópia por nó, e recusou a terceira. A afinidade então pôs cada sidekick ao lado de uma cópia."}
```

Essas regras custam trabalho ao scheduler. Para cada pod alocado, ele precisa olhar os pods de cada nó
candidato, então num cluster de milhares de nós, anti-afinidade em tudo deixa o agendamento mais lento. As topology spread constraints da lição 31 são a ferramenta mais barata quando o objetivo é só
espalhar.
