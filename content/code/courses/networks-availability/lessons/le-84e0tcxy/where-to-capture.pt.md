---
title: Onde pôr a captura
version: 1
---

A imagem comum é que qualquer máquina da rede do escritório consegue ver o tráfego do escritório,
bastando rodar o programa certo. **Numa rede com switch, não consegue.** O switch aprende qual endereço
MAC está atrás de cada porta, como `networks-addressing` mostrou, e manda um quadro
unicast só por aquela porta. Um laptop na porta vizinha vê o próprio tráfego, os broadcasts e quase
mais nada.

A rede da aula 1 mostra isso. Comece a captura em `laptop`, que fica no mesmo switch, e enquanto ela
corre os seus cinco segundos, busque uma página em `web1` a partir de `files` com
`curl -s http://192.0.2.21/`:

```
ana@laptop:~$ sudo timeout 5 tcpdump -n -i eth0 host 192.168.10.10 and not host 192.168.10.20
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:09:32.323256 ARP, Request who-has 192.168.10.1 tell 192.168.10.10, length 28

1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

**Um pacote em cinco segundos, e era um broadcast.** `files` perguntou quem tem `192.168.10.1`, o
gateway dele, e um pedido ARP sai por todas as portas. A requisição HTTP e a página que voltou
passaram entre a porta de `files` e a porta de `hq`, e o switch nunca as copiou para a do laptop.

## Três lugares que veem o tráfego

**Uma porta espelho**, que a Cisco chama de SPAN, é uma configuração do switch que copia todo quadro
de uma porta, ou de uma VLAN inteira, para outra porta onde um analisador escuta. O `netlab.sh` tem um
verbo para isso. Na máquina virtual, `sudo bash netlab.sh span hq files` configura o switch da matriz
para espelhar a porta de `files` para `mon`, uma máquina com uma interface e nenhum endereço IP. Comece a
captura em `mon` e faça a mesma requisição em `files` de novo:

```
ana@mon:~$ tshark -n -i eth0 -c 6 -f "tcp port 80"
Capturing on 'eth0'
6 packets captured
    1 0.000000000 192.168.10.10 → 192.0.2.21   TCP 74 59920 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=1038947159 TSecr=0 WS=1024
    2 0.000077141   192.0.2.21 → 192.168.10.10 TCP 74 80 → 59920 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM TSval=3565941641 TSecr=1038947159 WS=1024
    3 0.000092290 192.168.10.10 → 192.0.2.21   TCP 66 59920 → 80 [ACK] Seq=1 Ack=1 Win=64512 Len=0 TSval=1038947159 TSecr=3565941641
    4 0.000160803 192.168.10.10 → 192.0.2.21   HTTP 139 GET / HTTP/1.1 
    5 0.000172681   192.0.2.21 → 192.168.10.10 TCP 66 80 → 59920 [ACK] Seq=1 Ack=74 Win=65536 Len=0 TSval=3565941641 TSecr=1038947159
    6 0.000388243   192.0.2.21 → 192.168.10.10 HTTP 309 HTTP/1.1 200 OK  (text/html)
```

Desta vez `mon` viu a conversa inteira: os três pacotes que abrem a conexão, o `GET`, a confirmação e
o `200 OK`. **`mon` não precisa de endereço para isso**, porque nunca participa de nada; ele lê cópias.
É também por isso que um analisador numa porta espelho é invisível para as máquinas que observa.

**Um tap** é um pequeno aparelho posto no próprio cabo. Ele deixa o tráfego passar e copia os dois
sentidos para uma porta de monitoração, seja qual for a configuração do switch. Custa dinheiro e um
instante de parada para instalar, e é a resposta quando não dá para confiar que a porta espelho esteja
completa. A rede deste curso não tem tap, então este é descrito e não mostrado.

**No próprio host** é o terceiro lugar, e muitas vezes o mais simples: capturar no servidor que está
com problema, onde todo pacote que ele manda ou recebe passa pela própria interface. Isso é a aula 12,
com `tcpdump` em `web1`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um switch com quatro máquinas. Acima dele, files em 192.168.10.10 e hq em 192.168.10.1, ligados pelo switch na conversa HTTP, que usa só essas duas portas. Abaixo dele, laptop em 192.168.10.20, que viu um broadcast ARP em cinco segundos, e mon, sem endereço, numa porta espelho que recebe uma cópia de todo quadro da porta de files.\"><defs><marker id=\"wh-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"wh-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"60\" y=\"20\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files</text><text x=\"135.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.10</text><rect x=\"460\" y=\"20\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"535.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.1</text><rect x=\"60\" y=\"124\" width=\"550\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"335\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">switch</text><rect x=\"60\" y=\"230\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mon</text><text x=\"135\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem endereço</text><rect x=\"460\" y=\"230\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"535.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><path d=\"M135 66 L135 124\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M535 66 L535 124\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M135 174 L135 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M535 174 L535 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M165 70 L165 122\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#wh-am)\"></path><path d=\"M505 122 L505 70\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#wh-am)\"></path><path d=\"M105 176 L105 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#wh-ph)\"></path><text x=\"335\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">HTTP: só a porta de files e a porta de hq</text><text x=\"335\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">encaminha pelo endereço MAC, da porta de files para a porta de hq</text><text x=\"222\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">porta espelho: cópia de</text><text x=\"222\" y=\"261\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">todo quadro de files</text><text x=\"622\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">viu um ARP</text><text x=\"622\" y=\"261\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">broadcast em 5 s</text></svg>", "caption": "As duas capturas da primeira seção. Um switch entrega um quadro unicast a uma porta só, então o laptop viu apenas o broadcast; a porta espelho entrega a mon uma cópia de tudo o que files manda e recebe.", "same": ["switch"]}
```

A porta espelho tem um limite que convém conhecer antes de confiar nela. **Ela copia para uma porta de
velocidade fixa.** Espelhe um uplink ocupado de 10 Gbit/s para uma porta de 1 Gbit/s e o switch
descarta as cópias para as quais não tem espaço. A captura então parece mostrar pacotes perdidos na
rede, quando eles se perderam no caminho até o analisador.
