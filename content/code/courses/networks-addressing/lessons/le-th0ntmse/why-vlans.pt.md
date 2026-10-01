---
title: Um switch, várias redes
version: 1
---

A aula 18 terminou numa regra: um switch manda um broadcast para fora de toda porta, então tudo o
que está ligado nele é um domínio de broadcast, e só um roteador encerra um. A conclusão de costume
é que dois departamentos que não podem dividir um domínio de broadcast precisam de dois switches.
Não precisam. **Uma VLAN (*virtual LAN*, LAN virtual) é um domínio de broadcast desenhado na
configuração do switch em vez de nos cabos**: cada porta recebe um número de VLAN, e um quadro que
entra na VLAN 10 só pode sair por uma porta da VLAN 10. Um switch vira vários, e nada é
desconectado.

O laboratório desta aula são dois switches, sw1 e sw2, ligados por um cabo entre as portas p24 de
cada um, e cinco PCs. O pc1 e o pc3 são de um departamento e têm endereços em 10.20.10.0/24; o pc2
e o pc4 são de outro, em 10.20.20.0/24. O pc5 é o diferente: o endereço dele está na faixa do
primeiro departamento, e a porta dele vai para a VLAN do segundo, que é o experimento da última
seção. Os switches são a bridge do kernel Linux com a filtragem de VLAN ligada, configurada com o
comando `bridge vlan`. Um switch comercial diz as mesmas coisas com as palavras dele, e a aula diz
quais são onde elas diferem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O laboratório da aula 19. O switch sw1 tem o pc1 na porta p1, endereço 10.20.10.21, na VLAN 10, e o pc2 na porta p2, endereço 10.20.20.22, na VLAN 20. O switch sw2 tem o pc3 na p1, 10.20.10.23, VLAN 10; o pc4 na p2, 10.20.20.24, VLAN 20; e o pc5 na p3, 10.20.10.25, VLAN 20. Os dois switches são ligados por um cabo da p24 à p24, que vira o tronco. O endereço do pc5 está na sub-rede da VLAN 10, e a porta dele está na VLAN 20.\"><defs><marker id=\"v19t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"80\" y1=\"84\" x2=\"135\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"20\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.21</text><text x=\"32\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"143\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><line x1=\"230\" y1=\"84\" x2=\"215\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"170\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"182\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.20.22</text><text x=\"182\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"207\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><line x1=\"390\" y1=\"84\" x2=\"475\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"330\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"342\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"342\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.23</text><text x=\"342\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">VLAN 10</text><text x=\"483\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><line x1=\"520\" y1=\"84\" x2=\"525\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"460\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"472\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc4</text><text x=\"472\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.20.24</text><text x=\"472\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"533\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><line x1=\"650\" y1=\"84\" x2=\"575\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"590\" y=\"20\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc5</text><text x=\"602\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">10.20.10.25</text><text x=\"602\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">VLAN 20</text><text x=\"567\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><line x1=\"255\" y1=\"192\" x2=\"445\" y2=\"192\" stroke=\"var(--paper)\" stroke-width=\"3\"></line><rect x=\"95\" y=\"170\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"445\" y=\"170\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"175\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><text x=\"525\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw2</text><text x=\"262\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p24</text><text x=\"438\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p24</text><text x=\"350\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um cabo</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O endereço do pc5 está na sub-rede da VLAN 10; a porta dele está na VLAN 20.</text><text x=\"20\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">VLANs das portas como esta aula as configura. Antes disso, toda porta está na VLAN 1.</text></svg>", "caption": "O laboratório desta aula: dois switches ligados pela p24, cinco PCs e dois departamentos. O pc5 é o erro proposital, com um endereço de um departamento e uma porta na VLAN do outro.", "same": ["VLAN 10", "VLAN 20"]}
```

Antes de qualquer configuração, toda porta está na **VLAN 1, a VLAN padrão** com que quase todo
switch sai de fábrica:

```
root@sw1:~# bridge vlan show
port              vlan-id  
p1                1 PVID Egress Untagged
p2                1 PVID Egress Untagged
p24               1 PVID Egress Untagged
br0               1 PVID Egress Untagged
```

Cada linha é uma porta e as VLANs a que ela pertence. `PVID` marca a VLAN em que é colocado um
quadro sem tag que chega por aquela porta, e `Egress Untagged` diz que os quadros daquela VLAN saem
da porta sem tag; as próximas três seções desmontam as duas palavras. `br0` é o próprio switch, a
interface que ele usaria se tivesse um endereço seu. As quatro linhas dizem a mesma coisa: uma VLAN,
e todo mundo nela.

Então o pc2, no outro departamento, ouve o que o pc1 diz ao pc3. O pc1 pingou o pc3 enquanto o pc2
rodava o `tcpdump` num segundo terminal, e é por isso que a saída do tcpdump vem depois do ping:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 8.756/8.756/8.756/0.000 ms
root@pc2:~# timeout 6 tcpdump -n -e -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:00:09.729306 02:25:70:bc:29:c6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.10.23 tell 10.20.10.21, length 28

1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

O pedido ARP foi para `ff:ff:ff:ff:ff:ff`, e o pc2 o recebeu, embora nada no pc2 tenha a ver com
10.20.10.23. Com cinco PCs isso é uma linha de saída. Num andar com algumas centenas de máquinas,
toda pergunta ARP, todo pedido DHCP e toda impressora se anunciando chega a todas elas, e toda placa
de rede tem de receber o quadro e todo sistema operacional tem de olhar para ele antes de jogá-lo
fora. Todo mundo também vê quem está perguntando por quem, e um departamento com outro nível de
confiança não tem nada que ver isso.

Isso dá três motivos para dividir uma rede, e cada um é de um tipo diferente. O primeiro é tamanho:
**o tráfego de broadcast cresce com o número de máquinas no domínio**, então um domínio é mantido
pequeno o bastante para que o falatório dele continue sendo ruído de fundo. O segundo é controle: o
tráfego entre duas VLANs tem de passar por um roteador, e um roteador é um lugar onde uma regra pode
dizer quem fala com quem, que é a aula 22. O terceiro é organização: uma VLAN segue uma função e não
uma mesa, então a VLAN do financeiro pode existir em todo andar e em todo switch sem um cabo próprio.

O que uma VLAN não faz importa tanto quanto. Ela não criptografa nada, e não decide quem pode se
ligar — isso é segurança de porta e 802.1X, da aula 18. **A convenção que este laboratório segue é
uma VLAN por sub-rede IP**: 10.20.10.0/24 vive na VLAN 10 e 10.20.20.0/24 na VLAN 20, então o
domínio de broadcast e a sub-rede são o mesmo conjunto de máquinas. O pc5 quebra essa convenção de
propósito, e a última seção mostra o que acontece quando o endereço diz uma coisa e a porta diz
outra.
