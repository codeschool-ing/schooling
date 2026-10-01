---
title: LACP, as duas pontas combinando
version: 1
---

Um LAG pode ser configurado sem protocolo nenhum: diga a cada switch quais portas andam juntas e ele
espalha o tráfego por elas. Esse é um LAG **estático**, e a fraqueza dele é que cada ponta confia na
própria configuração e em mais nada. Se um cabo do grupo for ligado ao switch errado, ou se a outra
ponta nunca foi configurada, a ponta de cá manda parte do tráfego para uma porta que não o espera, e
nada acusa falha.

O **LACP**, *Link Aggregation Control Protocol*, faz as duas pontas conferirem uma à outra. Ele foi
publicado como IEEE 802.3ad e hoje mora no IEEE 802.1AX, e é por isso que o Linux ainda chama o modo
de `802.3ad`. Cada ponta manda **LACPDUs** em cada membro: quem ela é (uma prioridade de sistema e um
MAC), a que grupo a porta pertence (uma *chave*, *key*) e o estado da porta. **Uma porta só entra no
LAG quando o parceiro na outra ponta daquele cabo concorda** com o mesmo grupo. Um cabo ligado ao
switch errado mostra o parceiro errado, e fica de fora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O laboratório da lição 21. O pc1 está na porta p1 do sw1. O sw1 e o sw2 estão ligados por dois cabos, e1 e e2 em cada ponta, agrupados em cada switch numa porta lógica, bond0, que fica na bridge br0 do switch. O bond do sw1 usa o endereço MAC 02:1d:22:fd:7e:72 e vê o sw2, 02:fc:ce:91:32:14, como parceiro LACP nos dois cabos. pc2, pc3 e pc4 estão no sw2, em 10.20.10.22, 10.20.10.23 e 10.20.10.24; o pc1 é 10.20.10.21. Cada switch manda um LACPDU em cada cabo a cada segundo.\"><defs><marker id=\"lag-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"96\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"62\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"62\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.21</text><path d=\"M108 116 L150 116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"140\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p1</text><rect x=\"150\" y=\"70\" width=\"140\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw1</text><rect x=\"206\" y=\"98\" width=\"76\" height=\"54\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"244\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bond0</text><text x=\"166\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">br0</text><rect x=\"430\" y=\"70\" width=\"140\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw2</text><rect x=\"438\" y=\"98\" width=\"76\" height=\"54\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"476\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bond0</text><text x=\"554\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">br0</text><path d=\"M282 128 L438 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"272\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e1</text><text x=\"448\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e1</text><path d=\"M282 142 L438 142\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"272\" y=\"142\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e2</text><text x=\"448\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">e2</text><path d=\"M304 116 H416 Q424 116 424 124 V146 Q424 154 416 154 H304 Q296 154 296 146 V124 Q296 116 304 116 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">um enlace lógico, dois cabos</text><path d=\"M360 64 L360 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#lag-p)\"></path><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um LACPDU em cada sentido, por segundo, em cada cabo</text><text x=\"220\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sw1, o ator</text><text x=\"220\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">02:1d:22:fd:7e:72</text><text x=\"500\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sw2, o parceiro</text><text x=\"500\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">02:fc:ce:91:32:14</text><rect x=\"612\" y=\"40\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"658\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"658\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.22</text><path d=\"M570 116 L612 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"612\" y=\"98\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"658\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"658\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.23</text><path d=\"M570 116 L612 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"612\" y=\"156\" width=\"92\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"658\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"658\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.10.24</text><path d=\"M570 116 L612 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "O spanning tree e a tabela MAC veem uma porta, bond0, em cada ponta. O LACP roda em cada cabo por baixo e só mantém um membro no grupo enquanto o parceiro naquele cabo concorda."}
```

## Agrupando os dois cabos no sw1

No `sw1`, quatro comandos criam um bond em modo LACP, põem os dois cabos nele e põem o bond no
switch:

```
root@sw1:~# ip link add bond0 type bond mode 802.3ad lacp_rate fast miimon 100 xmit_hash_policy layer2+3
root@sw1:~# ip link set e1 down && ip link set e2 down
root@sw1:~# ip link set e1 master bond0 && ip link set e2 master bond0
root@sw1:~# ip link set bond0 master br0 && ip link set bond0 up
```

A primeira linha carrega todas as decisões. `mode 802.3ad` é o LACP. **`lacp_rate fast` pede ao
parceiro um LACPDU a cada segundo** em vez de a cada 30, então um membro morto é percebido em
segundos. `miimon 100` faz o bond conferir o enlace de cada membro a cada 100 milissegundos.
`xmit_hash_policy layer2+3` decide como o tráfego se espalha, o que a próxima seção mostra. Os cabos
são desativados antes de entrar, e é por isso que o `Link Failure Count` de cada membro marca 1 mais
abaixo. Os mesmos quatro comandos rodaram no `sw2`, fora de vista, porque o LACP precisa das duas
pontas.

Dez segundos depois, o bond é uma interface com dois membros:

```
root@sw1:~# ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
br0              UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
bond0            UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
e1@if485         UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
e2@if487         UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> 
p1@if490         UP             02:b7:0a:5d:30:6c <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

`bond0` é o `MASTER` e os dois cabos são membros dele, marcados `SLAVE`, que é a palavra que o
kernel ainda imprime. **O bond pegou o endereço MAC do `e1`, `02:1d:22:fd:7e:72`, e o `e2` também**:
para o switch, uma porta lógica tem um endereço.

## O que o bond diz de si mesmo

O kernel descreve a negociação inteira num arquivo:

```
root@sw1:~# cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v6.8.0-142-generic

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer2+3 (2)
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

802.3ad info
LACP active: on
LACP rate: fast
Min links: 0
Aggregator selection policy (ad_select): stable
System priority: 65535
System MAC address: 02:1d:22:fd:7e:72
Active Aggregator Info:
	Aggregator ID: 1
	Number of ports: 2
	Actor Key: 15
	Partner Key: 15
	Partner Mac Address: 02:fc:ce:91:32:14

Slave Interface: e1
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 1
Permanent HW addr: 02:1d:22:fd:7e:72
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: monitoring
Partner Churn State: monitoring
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: 02:1d:22:fd:7e:72
    port key: 15
    port priority: 255
    port number: 1
    port state: 63
details partner lacp pdu:
    system priority: 65535
    system mac address: 02:fc:ce:91:32:14
    oper key: 15
    port priority: 255
    port number: 1
    port state: 63

Slave Interface: e2
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 1
Permanent HW addr: 02:ce:7c:39:59:d3
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: monitoring
Partner Churn State: monitoring
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: 02:1d:22:fd:7e:72
    port key: 15
    port priority: 255
    port number: 2
    port state: 63
details partner lacp pdu:
    system priority: 65535
    system mac address: 02:fc:ce:91:32:14
    oper key: 15
    port priority: 255
    port number: 2
    port state: 63
ana@pc1:~$ ping -c 2 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.928/2.420/3.912/1.492 ms
```

Leia de cima para baixo. **`Aggregator ID: 1` com `Number of ports: 2`** é a primeira coisa a
conferir: os dois cabos entraram no mesmo agregador. `Partner Mac Address: 02:fc:ce:91:32:14` é o
`sw2`, e o mesmo endereço aparece como parceiro nos dois membros, que é a conferência que um LAG
estático nunca faz. `Actor Key: 15` e `Partner Key: 15` são as duas pontas nomeando o mesmo grupo.
Neste arquivo o *actor* (ator) é a ponta onde você está lendo, e o *partner* (parceiro) é a ponta de
lá.

Cada membro mostra então o LACPDU que manda e o que recebeu. **`port state: 63` dos dois lados** é
um byte de seis flags, todas ligadas: a porta está mandando LACPDUs ativamente, usando o timeout
rápido, disposta a agregar, sincronizada com o parceiro, coletando quadros e distribuindo-os. Um
membro com cabo e ativo mas ainda não sincronizado mostraria um número menor.

E o ping que falhou na seção anterior agora atravessa o bond: 2 enviados, 2 recebidos.
