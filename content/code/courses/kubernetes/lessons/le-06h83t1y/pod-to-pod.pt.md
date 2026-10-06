---
title: Todo pod tem um endereço que todo outro pod alcança
version: 1
---

**Quem vem do Docker espera que os containers se escondam atrás do endereço do host, com portas
publicadas para fora.** O Kubernetes pede o contrário. O modelo de rede dele tem três regras: todo pod
recebe um endereço próprio; todo pod alcança todo outro pod nesse endereço, em qualquer nó, sem
tradução de endereço; e os agentes de um nó alcançam todos os pods dele. O que o plugin faz é tornar
essas três regras verdadeiras.

O primeiro passo é uma faixa por nó. Cada nó recebe uma fatia da faixa de pods do cluster, e todo pod
nele pega um endereço dessa fatia:

```
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address,POD-CIDR:.spec.podCIDR
NAME                 ADDRESS      POD-CIDR
shop-control-plane   172.18.0.2   10.244.0.0/24
shop-worker          172.18.0.3   10.244.2.0/24
shop-worker2         172.18.0.4   10.244.1.0/24
```

`shop-worker` distribui `10.244.2.x`, `shop-worker2` distribui `10.244.1.x`. Dois pods presos aos dois
workers, indicando o nó no spec:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: left
spec:
  nodeName: shop-worker
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: right
spec:
  nodeName: shop-worker2
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
```

```
ana@laptop:~/shop$ kubectl apply -f pods.yaml
pod/left created
pod/right created
ana@laptop:~/shop$ kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
left    1/1     Running   0          1s    10.244.2.2   shop-worker    <none>           <none>
right   1/1     Running   0          1s    10.244.1.2   shop-worker2   <none>           <none>
```

## De dentro de um pod

```
ana@laptop:~/shop$ kubectl exec left -- ip -4 addr show eth0
2: eth0@if3: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue qlen 1000
    inet 10.244.2.2/24 brd 10.244.2.255 scope global eth0
       valid_lft forever preferred_lft forever
ana@laptop:~/shop$ kubectl exec left -- ip route
default via 10.244.2.1 dev eth0 
10.244.2.0/24 via 10.244.2.1 dev eth0  src 10.244.2.2 
10.244.2.1 dev eth0 scope link  src 10.244.2.2 
```

`left` tem uma interface, `eth0`, com `10.244.2.2/24`, e toda rota passa por `10.244.2.1`. Esse
endereço fica no nó, na outra ponta do cabo do pod, e é a única saída do pod.

```
ana@laptop:~/shop$ kubectl exec left -- ping -c 3 10.244.1.2
PING 10.244.1.2 (10.244.1.2): 56 data bytes
64 bytes from 10.244.1.2: seq=0 ttl=62 time=0.375 ms
64 bytes from 10.244.1.2: seq=1 ttl=62 time=0.121 ms
64 bytes from 10.244.1.2: seq=2 ttl=62 time=0.123 ms

--- 10.244.1.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.121/0.206/0.375 ms
```

**Três pacotes de ida, três de volta, bem abaixo de um milissegundo cada, e o `ttl` voltou em 62**: a
resposta foi roteada duas vezes no caminho, uma por cada nó. O caminho, um salto de cada vez:

```
ana@laptop:~/shop$ kubectl exec left -- traceroute -n -m 4 10.244.1.2
traceroute to 10.244.1.2 (10.244.1.2), 4 hops max, 46 byte packets
 1  10.244.2.1  0.006 ms  0.002 ms  0.005 ms
 2  172.18.0.4  0.002 ms  0.001 ms  0.001 ms
 3  10.244.1.2  0.002 ms  0.002 ms  0.002 ms
```

O salto 1 é o próprio nó de `left`, `10.244.2.1`. O salto 2 é `172.18.0.4`, o endereço de
`shop-worker2`. O salto 3 é o próprio `right`. **Não há túnel nem tradução em nenhum ponto desse
caminho**: o pacote saiu com o endereço real de `right` e chegou com o mesmo, que é a segunda regra do
modelo funcionando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois nós na rede 172.18.0.0/16. Em shop-worker, o pod left, em 10.244.2.2, é ligado por um cabo veth ao gateway do nó, 10.244.2.1. A tabela de rotas do nó diz 10.244.1.0/24 via 172.18.0.4. O pacote atravessa para shop-worker2, em 172.18.0.4, que tem a rota 10.244.2.0/24 via 172.18.0.3 de volta, e o entrega por outro veth ao pod right, em 10.244.1.2. Três saltos numerados.\"><defs><marker id=\"hop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hop-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker</text><text x=\"324\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.3</text><rect x=\"36\" y=\"56\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"101.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">left</text><text x=\"101.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.2.2</text><rect x=\"36\" y=\"150\" width=\"288\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">route</text><text x=\"180.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.1.0/24 via 172.18.0.4</text><text x=\"250\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.244.2.0/24</text><rect x=\"380\" y=\"20\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-worker2</text><text x=\"684\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">172.18.0.4</text><rect x=\"396\" y=\"56\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"461.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">right</text><text x=\"461.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.1.2</text><rect x=\"396\" y=\"150\" width=\"288\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">route</text><text x=\"540.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.244.2.0/24 via 172.18.0.3</text><text x=\"610\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.244.1.0/24</text><path d=\"M40 250 L680 250\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a rede dos nós 172.18.0.0/16</text><path d=\"M166 100 L166 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hop-ah-phosphor)\"></path><text x=\"176\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">salto 1 · 10.244.2.1</text><path d=\"M300 202 L300 236 L460 236 L460 202\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hop-ah-phosphor)\"></path><text x=\"380\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">salto 2</text><path d=\"M526 148 L526 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#hop-ah-phosphor)\"></path><text x=\"536\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">salto 3</text></svg>", "caption": "O pacote leva o endereço real de right o caminho todo. Cada nó só precisa de uma rota para a fatia do outro nó."}
```
