---
title: O endereço que muda no roteador
version: 1
---

O NAT de origem é uma reescrita num sentido e o desfazer dela no outro, e um ping basta para ver as
duas coisas. No r1, `tcpdump -i any` escuta em todas as interfaces ao mesmo tempo e imprime por qual
delas cada pacote passou. Ele foi iniciado antes e ficou rodando enquanto o pc1 pingava um endereço lá
fora. O terminal do pc1 imprimiu:

```
ana@pc1:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=62 time=21.8 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 21.845/21.845/21.845/0.000 ms
```

e enquanto isso, no r1, o tcpdump tinha imprimido:

```
root@r1:~# timeout 6 tcpdump -n -i any -c 4 icmp
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
08:24:44.835307 eth0  In  IP 10.20.10.21 > 192.0.2.80: ICMP echo request, id 14, seq 1, length 64
08:24:44.845874 eth1  Out IP 203.0.113.2 > 192.0.2.80: ICMP echo request, id 14, seq 1, length 64
08:24:44.849379 eth1  In  IP 192.0.2.80 > 203.0.113.2: ICMP echo reply, id 14, seq 1, length 64
08:24:44.850008 eth0  Out IP 192.0.2.80 > 10.20.10.21: ICMP echo reply, id 14, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Quatro linhas, um pacote cada, e a coluna da interface conta a história:

1. `eth0  In`: o echo request chega do escritório, de `10.20.10.21` para `192.0.2.80`.
2. `eth1  Out`: o mesmo pedido sai para o provedor, **agora de `203.0.113.2`**. Só a origem mudou: o
   destino, o `id 14` do ICMP e o `seq 1` continuam iguais.
3. `eth1  In`: a resposta volta para `203.0.113.2`, o único endereço que a outra ponta viu.
4. `eth0  Out`: o r1 manda a resposta para dentro do escritório **para `10.20.10.21`**, devolvendo o
   que tinha tirado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Um ping atravessando o r1, nos quatro pacotes que o tcpdump imprimiu. 1: o echo request chega pela eth0 de 10.20.10.21 para 192.0.2.80. 2: ele sai pela eth1 de 203.0.113.2 para 192.0.2.80; a origem foi reescrita. 3: a resposta chega pela eth1 de 192.0.2.80 para 203.0.113.2. 4: ela sai pela eth0 de 192.0.2.80 para 10.20.10.21; o destino foi reescrito de volta.\"><defs><marker id=\"snat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lado do escritório, eth0</text><text x=\"550\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lado do provedor, eth1</text><rect x=\"330\" y=\"32\" width=\"60\" height=\"196\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">r1</text><text x=\"55\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1  pedido entra</text><rect x=\"55\" y=\"54\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"67\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">src 10.20.10.21</text><text x=\"67\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dst 192.0.2.80</text><path d=\"M285 79 L326 79\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"435\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2  pedido sai</text><rect x=\"435\" y=\"54\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">src 203.0.113.2</text><text x=\"447\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dst 192.0.2.80</text><path d=\"M390 79 L431 79\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"435\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3  resposta entra</text><rect x=\"435\" y=\"154\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src 192.0.2.80</text><text x=\"447\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">dst 203.0.113.2</text><path d=\"M435 179 L394 179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"55\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4  resposta sai</text><rect x=\"55\" y=\"154\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"67\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src 192.0.2.80</text><text x=\"67\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">dst 10.20.10.21</text><path d=\"M330 179 L289 179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#snat-ah)\"></path><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o campo em âmbar é o que o r1 reescreveu</text></svg>", "caption": "NAT de origem num ping. Na ida o r1 troca a origem; na volta troca o destino, usando o que anotou no passo 2."}
```

Como o r1 sabia, no passo 4, que uma resposta para 203.0.113.2 era do pc1? Ele se lembrou. No passo 2
ele escreveu uma entrada na tabela de rastreamento de conexões — esta conversa, deste endereço de
dentro, saiu com este endereço de fora — e a resposta do passo 3 bateu com ela. No ICMP a entrada é
indexada pelo `id` do echo, que faz o papel que a porta faz no TCP e no UDP. **Todo NAT é uma tabela
dessas entradas**, e a próxima seção lê uma.

Daí saem duas consequências para quem lê capturas. **Uma captura feita fora do r1 nunca mostra um
endereço privado**: o provedor, a outra ponta e tudo no meio veem 203.0.113.2 e mais nada. E a tradução
não aparece no TTL: a resposta chegou ao pc1 com `ttl=62`, dois a menos que os 64 com que saiu, porque
o r1 e o isp a encaminharam uma vez cada, reescrevendo ou não. Os 21.8 ms são da máquina virtual deste
laboratório e não dizem nada sobre NAT.
