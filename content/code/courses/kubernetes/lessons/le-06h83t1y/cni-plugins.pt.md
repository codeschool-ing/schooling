---
title: O que o plugin escreveu, e o que outros plugins fazem em vez disso
version: 1
---

As rotas que fizeram aqueles saltos estão nos nós, escritas pelo plugin. Em `shop-worker`:

```
ana@laptop:~/shop$ docker exec shop-worker ip route
default via 172.18.0.1 dev eth0 
10.244.0.0/24 via 172.18.0.2 dev eth0 
10.244.1.0/24 via 172.18.0.4 dev eth0 
10.244.2.2 dev vetha9f24dcd scope host 
172.18.0.0/16 dev eth0 proto kernel scope link src 172.18.0.3 
```

**Uma rota para cada outro nó**: `10.244.0.0/24` pelo nó do plano de controle, `10.244.1.0/24` por
`shop-worker2`. E uma rota para cada pod local, `10.244.2.2` direto na interface `veth` que é a ponta
do nó no cabo de `left`:

```
ana@laptop:~/shop$ docker exec shop-worker ip route get 10.244.2.2
10.244.2.2 dev vetha9f24dcd src 10.244.2.1 uid 0 
    cache 
```

Esse é o desenho inteiro do kindnet: rotas, mantidas em dia conforme nós entram e saem. Funciona porque
os três nós estão numa rede só, `172.18.0.0/16`, em que cada um alcança os outros diretamente. A
configuração do plugin, que o runtime de containers lê quando um pod é criado:

```
ana@laptop:~/shop$ docker exec shop-worker cat /etc/cni/net.d/10-kindnet.conflist

{
	"cniVersion": "0.3.1",
	"name": "kindnet",
	"plugins": [
	{
		"type": "ptp",
		"ipMasq": false,
		"ipam": {
			"type": "host-local",
			"dataDir": "/run/cni-ipam-state",
			"routes": [
				
				
				{ "dst": "0.0.0.0/0" }
			],
			"ranges": [
				
				
				[ { "subnet": "10.244.2.0/24" } ]
			]
		}
		,
		"mtu": 1500
		
	},
	{
		"type": "portmap",
		"capabilities": {
			"portMappings": true
		}
	}
	]
}
```

Dois plugins em cadeia. O `ptp` faz o cabo do pod (um par de interfaces virtuais, uma ponta no pod e
outra no nó) e o `host-local` distribui endereços da fatia deste nó, `10.244.2.0/24`. O `portmap` vem
em segundo e implementa o `hostPort`. É o contrato do CNI funcionando: **o runtime chama uma lista de
programas pequenos com uma configuração, e cada um faz uma parte da rede de um pod.**

## O que outros plugins fazem

Só rotas exigem todos os nós numa rede que aceite endereços de pod. Quando os nós estão em sub-redes
diferentes, ou a rede por baixo recusa endereços desconhecidos, um plugin ou embrulha os pacotes dos
pods em pacotes dos nós (uma **rede sobreposta**, como VXLAN) ou ensina as faixas de pods à rede real,
com BGP. Os plugins das nuvens seguem um terceiro caminho e dão aos pods endereços da própria rede da
nuvem.

| plugin | como os pods se alcançam | aplica política de rede | comum onde |
|---|---|---|---|
| kindnet | rotas entre nós numa rede só | sim, onde o kernel aceita o seu motor de nftables | clusters kind |
| Flannel | rede sobreposta VXLAN, ou rotas | não | clusters pequenos, o k3s por padrão |
| Calico | rotas com BGP, ou rede sobreposta; eBPF disponível | sim | em data centers próprios e em nuvens |
| Cilium | eBPF no kernel, rede sobreposta ou rotas | sim, até o nível HTTP | clusters que querem observabilidade e política juntas |
| o da própria nuvem (AWS VPC CNI, Azure CNI, o do GKE) | os pods recebem endereços da rede da nuvem | com um complemento ou embutido | clusters gerenciados |

**A coluna que decide a maioria das escolhas é a de política.** Um plugin que não aplica políticas de
rede as aceita e as ignora, e nada avisa; a lição 24 mostra como isso fica na máquina deste
laboratório, onde o motor do kindnet não conseguiu subir, e depois instala o Calico para torná-las
reais. As outras diferenças (rede sobreposta ou não, eBPF ou iptables)
importam para desempenho e depuração, e raramente são o que faz uma equipe trocar de plugin num
cluster já rodando, uma migração que ninguém faz por pouca coisa.
