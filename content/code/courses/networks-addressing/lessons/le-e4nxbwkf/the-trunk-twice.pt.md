---
title: Um ping, quatro travessias
version: 1
---

É fácil imaginar o roteador sentado entre as duas VLANs, com o tráfego atravessando-o de um lado para
o outro. Com um roteador em um braço não existe outro lado. **Todo pacote roteado de uma VLAN para
outra sobe o tronco até o roteador e desce de volta pelo mesmo cabo**, uma vez em cada VLAN.

O sw1 escutou a p8, o tronco até o r1, enquanto o pc1 mandava um ping ao pc2. A captura terminou
depois do ping, então a saída dela vem em segundo lugar:

```
ana@pc1:~$ ping -c 1 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 2.163/2.163/2.163/0.000 ms
root@sw1:~# timeout 6 tcpdump -n -e -i p8 -c 4 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on p8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:21:22.386201 02:25:70:bc:29:c6 > 02:1f:23:e7:e9:d5, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.10.21 > 10.20.20.22: ICMP echo request, id 139, seq 1, length 64
09:21:22.387313 02:1f:23:e7:e9:d5 > 02:fd:f2:d2:63:ba, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.10.21 > 10.20.20.22: ICMP echo request, id 139, seq 1, length 64
09:21:22.387713 02:fd:f2:d2:63:ba > 02:1f:23:e7:e9:d5, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.20.22 > 10.20.10.21: ICMP echo reply, id 139, seq 1, length 64
09:21:22.387765 02:1f:23:e7:e9:d5 > 02:25:70:bc:29:c6, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.20.22 > 10.20.10.21: ICMP echo reply, id 139, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Quatro quadros para um ping, o primeiro marcado `.386201` e o último `.387765` dentro do mesmo
segundo. Leia os endereços MAC e a VLAN de cada um:

1. `02:25:70:bc:29:c6 > 02:1f:23:e7:e9:d5`, `vlan 10`: o echo request do pc1, subindo o braço até o
   MAC do r1, na VLAN 10.
2. `02:1f:23:e7:e9:d5 > 02:fd:f2:d2:63:ba`, `vlan 20`: o mesmo pedido, já roteado, descendo do r1
   até o pc2, agora na VLAN 20.
3. `02:fd:f2:d2:63:ba > 02:1f:23:e7:e9:d5`, `vlan 20`: o echo reply do pc2, subindo até o r1.
4. `02:1f:23:e7:e9:d5 > 02:25:70:bc:29:c6`, `vlan 10`: a resposta, já roteada, descendo até o pc1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"Um ping do pc1 ao pc2 através de um roteador em um braço, como sequência de cima para baixo. Quatro linhas de vida: pc1, pc2, sw1 e r1. O pc1 manda o echo request sem tag ao sw1. Travessia 1: o sw1 o manda tronco acima ao r1 na VLAN 10, capturado em .386201. Travessia 2: o r1 o devolve ao sw1 na VLAN 20, em .387313. O sw1 o entrega sem tag ao pc2. O pc2 manda o echo reply sem tag ao sw1. Travessia 3: o sw1 manda a resposta ao r1 na VLAN 20, em .387713. Travessia 4: o r1 a devolve na VLAN 10, em .387765. O sw1 a entrega sem tag ao pc1. As quatro travessias acontecem no tronco p8 entre o sw1 e o r1, onde o tcpdump escutou.\"><defs><marker id=\"v22t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"400\" y=\"58\" width=\"240\" height=\"244\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></rect><line x1=\"70\" y1=\"50\" x2=\"70\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"30\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"70\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><line x1=\"190\" y1=\"50\" x2=\"190\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"150\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><line x1=\"400\" y1=\"50\" x2=\"400\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"360\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><line x1=\"640\" y1=\"50\" x2=\"640\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><rect x=\"600\" y=\"20\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><line x1=\"70\" y1=\"84\" x2=\"394\" y2=\"84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"235.0\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pedido, sem tag</text><line x1=\"400\" y1=\"112\" x2=\"634\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · pedido, VLAN 10</text><text x=\"392\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.386201</text><line x1=\"640\" y1=\"140\" x2=\"406\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 · pedido, VLAN 20</text><text x=\"392\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.387313</text><line x1=\"400\" y1=\"168\" x2=\"196\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"295.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pedido, sem tag</text><line x1=\"190\" y1=\"196\" x2=\"394\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"295.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">resposta, sem tag</text><line x1=\"400\" y1=\"224\" x2=\"634\" y2=\"224\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · resposta, VLAN 20</text><text x=\"392\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.387713</text><line x1=\"640\" y1=\"252\" x2=\"406\" y2=\"252\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#v22t-ah)\"></line><text x=\"520.0\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 · resposta, VLAN 10</text><text x=\"392\" y=\"252\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.387765</text><line x1=\"400\" y1=\"280\" x2=\"76\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#v22t-ah)\"></line><text x=\"235.0\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">resposta, sem tag</text><text x=\"520\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o tronco p8, onde o tcpdump escutou</text></svg>", "caption": "Um ping, lido de cima para baixo. O pedido e a resposta cruzam o tronco duas vezes cada, uma em cada VLAN; os horários são os que o tcpdump marcou na p8, dentro do mesmo segundo."}
```

Os endereços IP não mudam em momento nenhum, `10.20.10.21 > 10.20.20.22` na ida e o contrário na
volta. O que muda é o quadro em volta do pacote: **a cada passagem pelo roteador, os endereços MAC e o
tag de VLAN são reescritos, e os endereços IP lá dentro continuam como estavam** (o roteador também
diminui o TTL em um, que esta captura não mostra). É isso que o roteamento faz com todo pacote, visto
aqui num só cabo. Todo quadro tem 102 bytes, o tamanho com tag que a aula 19 mediu.

O custo sai da contagem. **Um tronco até um roteador em um braço leva cada pacote roteado duas
vezes**, uma subindo e uma descendo. O cabo é full duplex, então a subida e a descida usam os dois
sentidos dele e não competem entre si; mas toda conversa entre todo par de VLANs divide esses dois
sentidos, junto com o que for endereçado ao próprio roteador. Se o braço é um enlace de 1 Gb/s, então
1 Gb/s em cada sentido é o máximo que consegue passar entre todas as VLANs juntas, por mais rápido
que o switch seja por dentro. O tráfego que fica dentro de uma VLAN nunca toca o braço: o pc1 e o
srv conversam só pelo sw1.

É por isso que o projeto é comum em lugares pequenos e raro nos grandes. Quando o tráfego entre VLANs
cresce, as opções são um enlace mais rápido ou agregado até o roteador (a aula 21 junta dois cabos em
um), ou levar o roteamento para onde o tráfego já está, dentro do switch, que é a próxima seção.
