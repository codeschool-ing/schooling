---
title: "Um relay: DHCP através de um roteador"
version: 1
---

O DHCP começa com um broadcast, e **um roteador não encaminha broadcasts**: é isso que faz dele a
borda de um domínio de broadcast, que a aula 18 mede. O pc4 está no segundo andar, 10.20.20.0/24, do
outro lado do r1 em relação ao servidor. Aqui ele pede um endereço, e o `timeout 12` encerra o
cliente depois de doze segundos:

```
ana@pc4:~$ sudo timeout 12 dhclient -v -1 eth0 2>&1 | grep -E "DHCP|bound|No"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0x3731d01b)
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 5 (xid=0x3731d01b)
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 14 (xid=0x3731d01b)
```

Três DISCOVERs, com o cliente esperando 3, depois 5, depois 14 segundos entre eles enquanto recua, e
nenhum OFFER. O srv nunca os ouviu. O arquivo dele já tem um escopo para 10.20.20.0, então o endereço
está lá para ser emprestado; o que falta é um jeito de a pergunta chegar até ele.

Uma resposta é um servidor DHCP em cada sub-rede, o que dá muitos servidores para manter em sintonia.
A resposta de costume é um **agente de relay** no roteador. Ele escuta os broadcasts de DHCP do lado
do cliente e encaminha cada um, como um pacote unicast comum, a um servidor que lhe foi informado. No
Linux é o `dhcrelay` da ISC; num roteador Cisco é uma linha na interface, `ip helper-address`, que
este laboratório não roda. Aqui, `-id eth2` indica o lado de baixo, o do pc4, `-iu eth0` o lado de
cima, em direção ao srv, e 10.20.10.10 é o servidor:

```
root@r1:~# dhcrelay -4 -iu eth0 -id eth2 10.20.10.10
Requesting: eth0 as upstream: Y downstream: N
Requesting: eth2 as upstream: N downstream: Y
Internet Systems Consortium DHCP Relay Agent 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/
Listening on LPF/eth2/02:26:62:13:4f:3c
Sending on   LPF/eth2/02:26:62:13:4f:3c
Listening on LPF/eth0/02:1f:23:e7:e9:d5
Sending on   LPF/eth0/02:1f:23:e7:e9:d5
Sending on   Socket/fallback
```

O pc4 pede de novo, e desta vez recebe resposta. No srv, um `tcpdump` tinha sido iniciado num segundo
terminal; ele aparece depois do comando do pc4 porque imprimiu quando terminou:

```
ana@pc4:~$ sudo dhclient -v eth0 2>&1 | grep -E "DHCP|bound"
Internet Systems Consortium DHCP Client 4.4.3-P1
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0xf0af884c)
DHCPOFFER of 10.20.20.100 from 10.20.20.1
DHCPREQUEST for 10.20.20.100 on eth0 to 255.255.255.255 port 67 (xid=0x4c88aff0)
DHCPACK of 10.20.20.100 from 10.20.20.1 (xid=0xf0af884c)
bound to 10.20.20.100 -- renewal in 250 seconds.
root@srv:~# timeout 15 tcpdump -n -i eth0 -c 4 port 67
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:21:13.056946 IP 10.20.10.1.67 > 10.20.10.10.67: BOOTP/DHCP, Request from 02:25:46:c1:26:7d, length 300
08:21:14.085697 IP 10.20.10.10.67 > 10.20.20.1.67: BOOTP/DHCP, Reply, length 300
08:21:14.099165 IP 10.20.10.1.67 > 10.20.10.10.67: BOOTP/DHCP, Request from 02:25:46:c1:26:7d, length 300
08:21:14.107376 IP 10.20.10.10.67 > 10.20.20.1.67: BOOTP/DHCP, Reply, length 300
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Do pc4, a troca parece um DORA qualquer, com uma diferença: a oferta vem `from 10.20.20.1`, o
endereço do r1 no andar do pc4, porque é o relay que conversa com ele. A captura no srv mostra a
outra metade. Os pedidos chegam como `10.20.10.1.67 > 10.20.10.10.67`, do r1, da porta 67 para a
porta 67, com o endereço MAC do pc4 ainda dentro: `Request from 02:25:46:c1:26:7d`.

**As respostas vão para 10.20.20.1, não para o endereço de onde os pedidos vieram.** Antes de
encaminhar, o relay escreveu o seu próprio endereço na sub-rede do cliente num campo do pedido
chamado **giaddr** (*gateway IP address*).
O servidor usou esse campo duas vezes: para saber para
onde mandar a resposta e para escolher o escopo. O 10.20.20.1 cai dentro de `subnet 10.20.20.0`, então
o pc4 recebeu a oferta de 10.20.20.100, do pool daquele escopo. Este `tcpdump` não decodifica o
campo, o que exige `-v`, mas o destino das respostas é o próprio campo, lido de volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O relay de DHCP no r1. À esquerda, o andar do pc4, 10.20.20.0/24; à direita, o escritório, 10.20.10.0/24; o r1 está nos dois. O pc4 manda um broadcast de 0.0.0.0 para 255.255.255.255. O r1 o encaminha como unicast de 10.20.10.1 para o srv em 10.20.10.10, com o campo giaddr preenchido com 10.20.20.1. O srv responde 10.20.10.10 &gt; 10.20.20.1, o giaddr, e o r1 passa ao pc4 uma oferta de 10.20.20.100, vinda de 10.20.20.1.\"><defs><marker id=\"dr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"12\" width=\"348\" height=\"228\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"362\" y=\"12\" width=\"348\" height=\"228\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"20\" y=\"30\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"80\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cliente</text><rect x=\"300\" y=\"30\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"360\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">relay</text><rect x=\"580\" y=\"30\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"640\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servidor DHCP</text><line x1=\"142\" y1=\"120\" x2=\"298\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"220\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.0.0.0 &gt; 255.255.255.255</text><text x=\"220\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">broadcast</text><line x1=\"422\" y1=\"120\" x2=\"578\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"500\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.10.1 &gt; 10.20.10.10</text><text x=\"500\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">unicast, giaddr 10.20.20.1</text><line x1=\"578\" y1=\"182\" x2=\"422\" y2=\"182\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"500\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.10.10 &gt; 10.20.20.1</text><text x=\"500\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">resposta ao giaddr</text><line x1=\"298\" y1=\"182\" x2=\"142\" y2=\"182\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dr-ah)\"></line><text x=\"220\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">oferta de 10.20.20.100</text><text x=\"220\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">de 10.20.20.1</text><text x=\"20\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">andar do pc4, 10.20.20.0/24</text><text x=\"700\" y=\"226\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o escritório, 10.20.10.0/24</text></svg>", "caption": "O relay transforma o broadcast do pc4 num unicast para o srv, e o giaddr que ele acrescenta decide para onde vai a resposta e qual escopo é usado.", "same": ["relay", "broadcast", "unicast, giaddr 10.20.20.1"]}
```

E com o endereço vieram as opções daquele escopo:

```
ana@pc4:~$ ip route
default via 10.20.20.1 dev eth0 
10.20.20.0/24 dev eth0 proto kernel scope link src 10.20.20.100 
```

A rota padrão é 10.20.20.1, o gateway do próprio andar. O gateway do srv, 10.20.10.1, não serviria
ao pc4, que não tem como alcançar a sub-rede do escritório diretamente. **O escopo é escolhido pelo
lugar onde o cliente está, e o relay é quem diz ao servidor que lugar é esse.**

Um relay vai em cada interface de roteador voltada para clientes, e um servidor, ou um par deles por
redundância, passa a atender um prédio inteiro. O custo é uma dependência dos roteadores no meio do
caminho. Se o relay do r1 parar, um cliente novo no segundo andar não recebe endereço nenhum. Um
cliente que já tem um ainda consegue renová-lo, porque a renovação vai por unicast ao servidor, e o
r1 a roteia como qualquer outro pacote.
