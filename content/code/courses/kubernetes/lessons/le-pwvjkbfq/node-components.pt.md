---
title: O que roda em todo nó
version: 1
---

Um nó de trabalho não roda parte nenhuma do plano de controle. **Ele roda quatro coisas, e só uma
delas é um programa do Kubernetes no sentido comum**: o kubelet, que transforma os objetos do API
server em containers rodando. As outras três são um runtime de containers, o kube-proxy e um plugin
de rede, e cada uma responde a uma pergunta que o kubelet não responde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O nó do plano de controle tem o API server no meio, o etcd ao lado, e o escalonador e o controller manager embaixo. Dois nós de trabalho têm, cada um, um kubelet, o containerd, o kube-proxy, um plugin CNI e pods. Todo componente tem uma seta para o API server, e só o API server tem uma seta para o etcd. O kubectl também fala com o API server.\"><defs><marker id=\"ar-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ar-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"380\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nó do plano de controle</text><rect x=\"150\" y=\"50\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-apiserver</text><rect x=\"40\" y=\"50\" width=\"76\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"78.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">etcd</text><rect x=\"40\" y=\"150\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kube-scheduler</text><rect x=\"246\" y=\"150\" width=\"146\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"319.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">kube-controller-manager</text><path d=\"M130 150 L195 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><path d=\"M300 150 L265 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><path d=\"M118 72 L148 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-phosphor)\" marker-start=\"url(#ar-ah-phosphor)\"></path><text x=\"40\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">só o API server</text><text x=\"40\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">lê e escreve no etcd</text><rect x=\"450\" y=\"50\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kubectl</text><path d=\"M450 72 L312 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><rect x=\"20\" y=\"240\" width=\"330\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nó de trabalho</text><rect x=\"30\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kubelet</text><rect x=\"110\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"146.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">containerd</text><rect x=\"190\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"226.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"270\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"306.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">CNI</text><rect x=\"370\" y=\"240\" width=\"330\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nó de trabalho</text><rect x=\"380\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kubelet</text><rect x=\"460\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">containerd</text><rect x=\"540\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">kube-proxy</text><rect x=\"620\" y=\"268\" width=\"72\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"656.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">CNI</text><path d=\"M66 238 L66 230 L222 230 L222 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path><path d=\"M416 238 L416 230 L234 230 L234 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ar-ah-paper-dim)\"></path></svg>", "caption": "Toda seta termina no API server. Os componentes nunca chamam uns aos outros, e nada além do API server toca o etcd."}
```

## O kubelet e o runtime são serviços, não pods

Num nó, o `systemd` os inicia como qualquer outro daemon:

```
ana@laptop:~/shop$ docker exec shop-worker systemctl is-active containerd kubelet
active
active
```

**O kubelet é o único componente que não pode rodar como pod**, porque é ele quem roda pods. Ele
observa o API server em busca de pods atribuídos ao seu nó e pede ao runtime de containers que os
inicie, por uma interface chamada CRI. O runtime aqui é o containerd, o mesmo que fica dentro do
Docker no curso `docker`, e o `crictl` é a ferramenta que fala CRI diretamente com ele:

```
ana@laptop:~/shop$ docker exec shop-worker2 crictl ps -o table
CONTAINER           IMAGE               CREATED                  STATE               NAME                ATTEMPT             POD ID              POD                    NAMESPACE
2de426ff547f5       c9131139e6342       Less than a second ago   Running             shop                0                   a3d9a1b867102       web-768c88b7c7-mlp9j   default
7c8ab5690b8fa       4626fe10df5b9       12 seconds ago           Running             kindnet-cni         0                   1488fdef332c1       kindnet-ftfrd          kube-system
5294a330f3551       d6a28daf3e6b0       13 seconds ago           Running             kube-proxy          0                   d627597dbe894       kube-proxy-5cmg7       kube-system
```

Três containers em `shop-worker2`. O primeiro é o `shop` da Ana, num pod com o nome do deployment
dela. Os outros dois são `kindnet-cni` e `kube-proxy`, e também são pods, em `kube-system`: um
DaemonSet (lição 12) põe uma cópia de cada em todo nó. Então o maquinário de rede do nó é iniciado
pelo kubelet como qualquer outra carga, e é por isso que atualizá-lo é um rollout e não um login em
cada máquina.

## kube-proxy: fazer o endereço de um Service chegar a um pod

Um Service recebe um endereço de `10.96.0.0/16` que nenhuma interface de rede tem. **O kube-proxy
observa os Services e os pods deles, e escreve regras no kernel do nó** (iptables ou nftables, conforme a configuração)
para que um pacote mandado para aquele endereço seja reescrito e chegue a um dos pods. Nada passa por
dentro do próprio kube-proxy, apesar do que o nome sugere; ele programa o kernel e sai do caminho. A
lição 17 lê essas regras.

## O plugin de rede: dar um endereço a um pod

Quando o runtime cria um pod, algo precisa dar a ele uma interface de rede, um endereço e uma rota
para todos os outros pods do cluster. Esse é o trabalho de um **plugin CNI**, um programa que o
runtime chama com uma configuração que encontra num diretório:

```
ana@laptop:~/shop$ docker exec shop-worker ls /etc/cni/net.d
10-kindnet.conflist
```

O kind instala o kindnet, que é simples e não faz mais nada. Clusters em produção rodam com mais
frequência o Calico ou o Cilium, que também aplicam políticas de rede, e a lição 18 os compara. O
ponto aqui é a forma: **o Kubernetes define o que a rede de um pod precisa fazer e deixa o como para
um plugin**, então o mesmo cluster roda num laptop, num data center e em cada nuvem, com um plugin
diferente em cada lugar.
