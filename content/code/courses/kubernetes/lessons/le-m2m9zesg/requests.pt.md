---
title: Um request é uma reserva
version: 1
---

Todo nó diz ao scheduler quanto tem para distribuir. **O allocatable é a capacidade do nó menos o que o
kubelet guarda para o sistema operacional e para si mesmo**, e é o número contra o qual toda alocação
é medida:

```
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory
NAME                 CPU   MEMORY
shop-control-plane   4     16480968Ki
shop-worker          4     16480968Ki
shop-worker2         4     16480968Ki
```

Quatro CPUs e cerca de 16 GiB de memória em cada nó. CPU é contada em milicores: `1500m` é uma CPU e
meia, `100m` é um décimo de uma.

Um request diz quanto disso um container precisa ter reservado. O Deployment abaixo pede uma CPU e
meia por cópia, cinco cópias:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: big
spec:
  replicas: 5
  selector:
    matchLabels:
      app: big
  template:
    metadata:
      labels:
        app: big
    spec:
      containers:
      - name: shop
        image: shop:1.0
        resources:
          requests:
            cpu: "1500m"
            memory: 64Mi
```

```
ana@laptop:~/shop$ kubectl apply -f big.yaml
deployment.apps/big created
ana@laptop:~/shop$ kubectl get pods -l app=big -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
big-749579674d-ddttp   1/1     Running   0          10s   10.244.2.5   shop-worker    <none>           <none>
big-749579674d-fzpjd   1/1     Running   0          10s   10.244.1.3   shop-worker2   <none>           <none>
big-749579674d-gl76z   0/1     Pending   0          10s   <none>       <none>         <none>           <none>
big-749579674d-t9g9m   1/1     Running   0          10s   10.244.1.4   shop-worker2   <none>           <none>
big-749579674d-wtg9l   1/1     Running   0          10s   10.244.2.4   shop-worker    <none>           <none>
```

**Quatro rodaram e uma ficou `Pending`.** O evento do scheduler diz por quê:

```
ana@laptop:~/shop$ kubectl get events --field-selector reason=FailedScheduling -o custom-columns=MESSAGE:.message | tail -n 1
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. preemption: 0/3 nodes are available: 1 Preemption is not helpful for scheduling, 2 No preemption victims found for incoming pod.
```

O nó control-plane tem um taint que mantém pods comuns fora dele (a lição 30 é sobre taints), e os
dois workers tinham, cada um, "insufficient cpu". A metade da mensagem sobre preempção diz que nenhum
pod rodando podia ser despejado para abrir espaço, o que a lição 31 explica. A conta do próprio nó
mostra a aritmética:

```
ana@laptop:~/shop$ kubectl describe node shop-worker | grep -A 8 "Allocated resources"
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                3200m (80%)  0 (0%)
  memory             248Mi (1%)   170Mi (1%)
  ephemeral-storage  0 (0%)       0 (0%)
  hugepages-1Gi      0 (0%)       0 (0%)
  hugepages-2Mi      0 (0%)       0 (0%)
```

`3200m (80%)`: duas cópias de `big` com 1500m cada, mais 200m que pods que o cluster roda para si mesmo
já tinham pedido: 100m do plugin de rede e 100m da cópia do CoreDNS neste nó. Sobravam 800m, e a quinta cópia precisava de 1500m.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas barras, uma por nó worker, cada uma com 4 CPUs de largura. Em shop-worker: 200m já pedidos pelos pods do próprio nó, depois dois pods de big com 1500m cada, o que deixa 800m livres. shop-worker2 é igual. Um quinto pod de big, pedindo 1500m, aparece ao lado, Pending, porque 800m é menos que 1500m nos dois nós.\"><defs><marker id=\"fit-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker</text><rect x=\"130\" y=\"40\" width=\"460.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"130\" y=\"40\" width=\"23.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"153.0\" y=\"40\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"239.25\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"239.25\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><rect x=\"325.5\" y=\"40\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"411.75\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"411.75\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><text x=\"544.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">800m livres</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker2</text><rect x=\"130\" y=\"120\" width=\"460.0\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"130\" y=\"120\" width=\"23.0\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"153.0\" y=\"120\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"239.25\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"239.25\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><rect x=\"325.5\" y=\"120\" width=\"172.5\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"411.75\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"411.75\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><text x=\"544.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">800m livres</text><text x=\"141.5\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">sistema</text><rect x=\"620\" y=\"75\" width=\"84\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"662.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">big</text><text x=\"662.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1500m</text><text x=\"662\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Pending</text><text x=\"662\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">precisa de 1500m</text><text x=\"130\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"590.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4000m</text><path d=\"M130 188 L590.0 188\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "O scheduler soma requests, não uso. Os dois nós estavam quase parados, e nenhum tinha 1500m sobrando para prometer."}
```

**O scheduler soma requests, nunca uso.** A loja ficou parada o tempo todo, usando quase nada de CPU,
e o quinto pod mesmo assim não tinha para onde ir. Esse é o acordo que um request faz: o pod tem
garantido o que pediu, então o scheduler nunca pode prometer o mesmo milicore duas vezes. Pedir demais
desperdiça nós, o que a lição 21 mede. Pedir de menos amontoa pods num nó que não consegue rodar todos
em velocidade total.

Um pod sem request nenhum não reserva nada, e o scheduler pode colocá-lo em qualquer lugar. Isso é
cômodo, e é também como um nó acaba rodando mais do que aguenta.
