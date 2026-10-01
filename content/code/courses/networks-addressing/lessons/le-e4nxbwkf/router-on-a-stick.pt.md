---
title: Roteador em um braço (router on a stick)
version: 1
---

**Um roteador em um braço (*router on a stick*) é um roteador com uma porta física, ligada num
tronco, com um endereço em cada VLAN que o tronco leva.** O nome é o desenho: um cabo, o braço, entre
o switch e o roteador. O roteador não precisa de uma porta por VLAN porque o tronco já diz a ele, em
cada quadro, de que VLAN o quadro veio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Roteador em um braço, o laboratório da aula 22. À esquerda, três máquinas ligadas ao switch sw1: pc1, 10.20.10.21, na VLAN 10 pela porta p1, gateway 10.20.10.1; srv, 10.20.10.10, na VLAN 10 pela porta p3, gateway 10.20.10.1; pc2, 10.20.20.22, na VLAN 20 pela porta p2, gateway 10.20.20.1. À direita, o roteador r1, ligado ao sw1 por um cabo a partir da porta p8, um tronco que leva as VLANs 10 e 20 com tag. O r1 tem uma porta, eth0, e duas interfaces de VLAN nela: eth0.10 com 10.20.10.1/24 e eth0.20 com 10.20.20.1/24.\"><defs><marker id=\"v22s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"190\" y1=\"51\" x2=\"300\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"20\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"178\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.21</text><text x=\"32\" y=\"69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gw 10.20.10.1</text><text x=\"292\" y=\"84\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><line x1=\"190\" y1=\"125\" x2=\"300\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"94\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"178\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"32\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.10</text><text x=\"32\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gw 10.20.10.1</text><text x=\"292\" y=\"107\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><line x1=\"190\" y1=\"199\" x2=\"300\" y2=\"138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"168\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"178\" y=\"182\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"32\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.20.22</text><text x=\"32\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gw 10.20.20.1</text><text x=\"292\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><rect x=\"300\" y=\"80\" width=\"100\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><line x1=\"400\" y1=\"115\" x2=\"520\" y2=\"115\" stroke=\"var(--paper)\" stroke-width=\"3\"></line><text x=\"408\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p8</text><text x=\"460\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o tronco: VLANs 10 e 20, com tag</text><rect x=\"520\" y=\"60\" width=\"190\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"534\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"534\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">eth0.10  10.20.10.1/24</text><text x=\"534\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">eth0.20  10.20.20.1/24</text><text x=\"534\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma porta: eth0</text></svg>", "caption": "Um cabo entre o switch e o roteador, e nele cada VLAN que o roteador atende. O roteador responde a cada VLAN pela própria interface, no endereço que as máquinas daquela VLAN usam como gateway.", "same": ["VLAN 10", "VLAN 20"]}
```

No r1 o tronco chega pelo eth0. O Linux dá a cada VLAN uma interface própria em cima dele, e os dois
primeiros comandos as criam:

```
root@r1:~# ip link add link eth0 name eth0.10 type vlan id 10
root@r1:~# ip link add link eth0 name eth0.20 type vlan id 20
root@r1:~# ip addr add 10.20.10.1/24 dev eth0.10 && ip addr add 10.20.20.1/24 dev eth0.20
root@r1:~# ip link set eth0.10 up && ip link set eth0.20 up
```

`eth0.10` é uma **interface de VLAN**: um quadro que chega no eth0 com tag da VLAN 10 é entregue ao
`eth0.10` sem o tag, e um pacote que sai pelo `eth0.10` deixa o eth0 com tag da VLAN 10. Cada uma
recebe então o endereço que os PCs da sua VLAN já indicam como gateway. A Cisco chama isso de
**subinterfaces** e as escreve `interface GigabitEthernet0/0.10`, com uma linha `encapsulation dot1Q
10` dentro; a ideia é a mesma, e o número também, que tem de bater com a VLAN do switch. O que o r1
tem agora:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0.10@eth0     UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth0.20@eth0     UP             10.20.20.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth0@if519       UP             fe80::1f:23ff:fee7:e9d5/64 
root@r1:~# ip route
10.20.10.0/24 dev eth0.10 proto kernel scope link src 10.20.10.1 
10.20.20.0/24 dev eth0.20 proto kernel scope link src 10.20.20.1 
```

Duas interfaces, `eth0.10@eth0` e `eth0.20@eth0`, cada uma com sua sub-rede, as duas montadas sobre
o eth0. O endereço IPv6 link-local é o mesmo nas três, `fe80::1f:23ff:fee7:e9d5`, porque é construído
a partir do endereço MAC e as três interfaces dividem um MAC. A tabela de rotas não precisou
de rota digitada: **o r1 está diretamente ligado às duas sub-redes**, então as duas linhas `proto
kernel` que surgiram com os endereços são tudo. O laboratório montou o r1 como roteador, o que quer
dizer que o encaminhamento entre interfaces já estava ligado.

```
ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 1.161/2.241/3.321/1.080 ms
ana@pc1:~$ traceroute -n 10.20.20.22
traceroute to 10.20.20.22 (10.20.20.22), 30 hops max, 60 byte packets
 1  10.20.10.1  2.189 ms  0.456 ms  0.441 ms
 2  10.20.20.22  0.450 ms  0.247 ms  0.325 ms
ana@pc2:~$ curl -s http://10.20.10.10/
served by srv
```

O pc1 alcança o pc2: dois enviados, dois recebidos. O traceroute mostra o formato, com **um salto por
10.20.10.1, o endereço do r1 na VLAN 10, e o pc2 no segundo**. E o pc2, na VLAN 20, busca a página
web do srv na VLAN 10, que é o motivo de o roteador ter sido posto ali.

Nada mudou nos PCs. Eles já mandavam para 10.20.10.1 e 10.20.20.1; a diferença é que agora alguém
responde nesses endereços. Um gateway configurado antes de o roteador existir é uma situação normal
numa rede em construção, e a entrada `INCOMPLETE` da seção anterior é a cara dela.

O roteador em um braço é comum onde o tráfego entre VLANs é leve: um escritório pequeno, uma filial
com um roteador que veio com uma ou duas portas, um laboratório. Custa uma porta de roteador e uma
porta de switch para qualquer número de VLANs, até as 4094 que o tag consegue nomear. O que ele custa
em capacidade é assunto da próxima seção, que observa um único ping cruzar o braço.
