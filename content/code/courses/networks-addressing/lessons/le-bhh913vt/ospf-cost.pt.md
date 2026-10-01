---
title: Custo OSPF: por que quatro enlaces vencem um
version: 1
---

O RIP mandou o tráfego de pc1 pelo cabo direto porque ele estava a um roteador de distância. **O OSPF não
conta roteadores. Ele soma um custo em cada interface por onde o pacote sai**, e fica com o caminho de
menor total. Neste laboratório o cabo direto de r1 a r2 recebeu custo 100, representando uma linha lenta, e
toda outra interface manteve o custo que o FRR lhe deu:

```
root@r1:~# vtysh -c "show ip ospf interface eth4" | grep -E "Cost"
  Router ID 10.20.1.1, Network Type POINTOPOINT, Cost: 10
```

`Cost: 10` em `eth4`, contra o `Cost: 100` em `eth1` da seção anterior. Normalmente o custo é calculado a
partir da velocidade da interface, uma largura de banda de referência dividida pela largura de banda do
enlace, então um enlace mais rápido custa menos; digitá-lo à mão, como aqui, substitui o cálculo.

As rotas que o OSPF calculou:

```
root@r1:~# vtysh -c "show ip route ospf"
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.20.0.0/30 [110/100] is directly connected, eth1, weight 1, 00:00:27
O>* 10.20.0.4/30 [110/30] via 10.20.0.13, eth4, weight 1, 00:00:06
O>* 10.20.0.8/30 [110/20] via 10.20.0.13, eth4, weight 1, 00:00:14
O   10.20.0.12/30 [110/10] is directly connected, eth4, weight 1, 00:00:27
O   10.20.1.0/24 [110/10] is directly connected, eth0, weight 1, 00:00:27
O>* 10.20.2.0/24 [110/40] via 10.20.0.13, eth4, weight 1, 00:00:06
```

O par entre colchetes é **`[distância/custo]`**: 110 é a distância administrativa do OSPF da aula 14, a
mesma em todas as linhas, e o segundo número é o custo do caminho. **A rede de pc2, `10.20.2.0/24`, custa
40, por `10.20.0.13`, que é r4**: o caminho longo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"O anel com o custo OSPF de cada interface. O cabo de r1 a r2 custa 100; toda outra interface custa 10, inclusive a interface de r2 na rede de pc2. De r1 até 10.20.2.0/24 o caminho direto custa 100 mais 10, 110. O caminho pela volta do anel, por r4, r3 e r2, custa 10 mais 10 mais 10 mais 10, 40, e o OSPF o escolhe. IDs de roteador: r1 10.20.1.1, r2 10.20.2.1, r3 10.20.0.9, r4 10.20.0.13.\"><defs><marker id=\"rc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"200\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.1.1</text><rect x=\"430\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"440\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.2.1</text><rect x=\"430\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"440\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.0.9</text><rect x=\"190\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><text x=\"200\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ID 10.20.0.13</text><rect x=\"20\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"590\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"600\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.10</text><path d=\"M130 95 L190 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M560 95 L590 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 95 L430 95\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M495 130 L495 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 245 L430 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M255 130 L255 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"375\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">custo 100</text><text x=\"505\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">custo 10</text><text x=\"375\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">custo 10</text><text x=\"245\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">custo 10</text><text x=\"575\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">custo 10</text><path d=\"M267 133 L267 207\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#rc-ah)\"></path><path d=\"M323 260 L427 260\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#rc-ah)\"></path><path d=\"M483 207 L483 133\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#rc-ah)\"></path><rect x=\"20\" y=\"300\" width=\"680\" height=\"66\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"36\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">de r1 até 10.20.2.0/24, somando o custo de cada interface por onde o pacote sai:</text><text x=\"36\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">direto: 100 + 10 = 110</text><text x=\"300\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">pela volta do anel: 10 + 10 + 10 + 10 = 40, escolhido</text><text x=\"36\" y=\"356\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O RIP contou roteadores, e escolheu o cabo direto.</text></svg>", "caption": "O custo é por interface e soma ao longo do caminho. Quatro enlaces baratos vencem um caro."}
```

Some a partir de r1. Sair por `eth4` em direção a r4 custa 10, de r4 a r3 custa 10, de r3 a r2 custa 10, e a
interface de r2 na rede de pc2 custa 10: **40**. O caminho direto custa 100 para chegar a r2 e mais 10 para a
rede de pc2: **110**. Quatro enlaces baratos vencem um caro, e o `traceroute` mostra os pacotes indo por lá:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  6.554 ms  0.604 ms  0.428 ms
 2  10.20.0.13  0.902 ms  0.219 ms  0.450 ms
 3  10.20.0.9  0.240 ms  0.212 ms  0.093 ms
 4  10.20.0.5  0.252 ms  0.119 ms  0.190 ms
 5  10.20.2.10  1.026 ms  0.274 ms  0.138 ms
```

Cinco saltos onde o RIP tinha três: r1, depois r4 em `10.20.0.13`, r3 em `10.20.0.9`, r2 em `10.20.0.5`, e
então pc2. **Os dois protocolos escolheram caminhos opostos nos mesmos cabos**, porque um conta roteadores
e o outro soma custos.

Dois detalhes na tabela de rotas valem um olhar mais atento. As linhas das redes do próprio r1, como
`10.20.0.0/30 [110/100] is directly connected`, não têm `>` nem `*`: o OSPF as conhece, mas a rota
conectada tem distância 0 e vence, então a cópia do OSPF não é usada. E `10.20.0.4/30`, o cabo entre r2 e
r3, custa 30 por r4: 10 até r4, 10 até r3, e 10 da interface de r3 nesse cabo.

O OSPF guarda sua própria visão do mesmo cálculo:

```
root@r1:~# vtysh -c "show ip ospf route"
============ OSPF network routing table ============
N    10.20.0.0/30          [100] area: 0.0.0.0
                           directly attached to eth1
N    10.20.0.4/30          [30] area: 0.0.0.0
                           via 10.20.0.13, eth4
N    10.20.0.8/30          [20] area: 0.0.0.0
                           via 10.20.0.13, eth4
N    10.20.0.12/30         [10] area: 0.0.0.0
                           directly attached to eth4
N    10.20.1.0/24          [10] area: 0.0.0.0
                           directly attached to eth0
N    10.20.2.0/24          [40] area: 0.0.0.0
                           via 10.20.0.13, eth4

============ OSPF router routing table =============

============ OSPF external routing table ===========


```

Cada rede com o custo total entre colchetes, e o roteador a quem entregá-la. A **tabela de roteadores**
(*router routing table*) e a **tabela externa** (*external routing table*) estão vazias porque nada neste
anel é borda de área nem traz rotas de fora do OSPF.

## Usando o custo de propósito

O custo é como você diz ao OSPF o que prefere. **Torne um enlace mais caro e o tráfego sai dele**, desde que
outro caminho some menos. A aritmética é a ferramenta inteira, e tem uma armadilha: se dois caminhos somam
o mesmo total, o OSPF usa os dois e divide o tráfego entre eles, o que é útil quando foi intencional e
confuso quando não foi.
