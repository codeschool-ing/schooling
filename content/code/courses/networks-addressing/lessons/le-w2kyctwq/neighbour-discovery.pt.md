---
title: Achar um vizinho sem ARP e sem broadcast
version: 1
---

O IPv6 não tem endereço de broadcast nenhum, nem ARP. O trabalho que o ARP fazia, transformar um
endereço IP num endereço MAC no mesmo enlace, é feito pelo **Neighbour Discovery** (descoberta de
vizinhos), um conjunto de mensagens ICMPv6 que inclui também os anúncios de roteador da seção
anterior. O que muda é quem é interrompido pela pergunta.

As duas tabelas de vizinhos foram esvaziadas antes desta captura, então o pc1 precisa perguntar. O pc1
pinga o srv e, enquanto isso, o `tcpdump` no srv imprimia o que chegava; a saída dele saiu depois que
o ping terminou:

```
ana@pc1:~$ ping -c 1 2001:db8:20:10::10
PING 2001:db8:20:10::10 (2001:db8:20:10::10) 56 data bytes
64 bytes from 2001:db8:20:10::10: icmp_seq=1 ttl=64 time=3.03 ms

--- 2001:db8:20:10::10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 3.029/3.029/3.029/0.000 ms
root@srv:~# timeout 6 tcpdump -n -c 4 -i eth0 icmp6
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:48:29.074885 IP6 2001:db8:20:10:25:70ff:febc:29c6 > ff02::1:ff00:10: ICMP6, neighbor solicitation, who has 2001:db8:20:10::10, length 32
07:48:29.076700 IP6 2001:db8:20:10::10 > 2001:db8:20:10:25:70ff:febc:29c6: ICMP6, neighbor advertisement, tgt is 2001:db8:20:10::10, length 32
07:48:29.077017 IP6 2001:db8:20:10:25:70ff:febc:29c6 > 2001:db8:20:10::10: ICMP6, echo request, id 10, seq 1, length 64
07:48:29.077113 IP6 2001:db8:20:10::10 > 2001:db8:20:10:25:70ff:febc:29c6: ICMP6, echo reply, id 10, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Quatro pacotes, na mesma ordem que o curso de redes mostrou para o ARP. Primeiro uma **neighbour
solicitation** (pedido de vizinho), *who has 2001:db8:20:10::10*, a partir do endereço global do pc1.
Depois a **neighbour advertisement** (anúncio de vizinho) do srv, *tgt is 2001:db8:20:10::10*, mandada
direto de volta para o pc1. Depois o próprio ping. O anúncio saiu do srv 1,815 milissegundo depois que
o pedido chegou, e isso é a máquina virtual deste laboratório, não uma propriedade do protocolo.

A parte interessante é o destino da pergunta. O ARP mandava a pergunta para `ff:ff:ff:ff:ff:ff`, e toda
máquina do enlace tinha de lê-la. **O pedido foi para `ff02::1:ff00:10`, um endereço multicast de nó
solicitado (*solicited-node*)**: `ff02::1:ff` seguido dos últimos 24 bits do endereço procurado. O
endereço do srv termina em `00:00:10` (os dois últimos grupos, `0000:0010`, dos quais se tomam os seis
últimos dígitos hexadecimais), então o grupo é `ff02::1:ff00:10`. Cada máquina entra no grupo de cada
um dos seus endereços, então na prática só a máquina com o endereço certo, e a rara cujo endereço
termine nos mesmos 24 bits, precisa olhar a pergunta. O pc2, cujos endereços terminam em `d2:63ba`,
está no grupo `ff02::1:ffd2:63ba` e nunca precisou ler esta.

A resposta vai para o mesmo tipo de tabela que o ARP preenche:

```
ana@pc1:~$ ip -6 neigh
2001:db8:20:10::10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

`02:9e:43:3e:ca:ae` é o MAC do srv, e dá para conferir com o endereço link-local do srv da primeira
seção desta aula, `fe80::9e:43ff:fe3e:caae`: os mesmos dígitos com `ff:fe` no meio e o `02` virado em
`00`.

Ainda há um jeito de alcançar todas as máquinas de um enlace, e ele também é um grupo multicast:
**`ff02::1`, todos os nós** (*all nodes*). Toda interface IPv6 entra nele. Pingue-o com uma zona, já que
endereços `ff02::` valem só no enlace, como os `fe80::`:

```
ana@pc1:~$ ping -w 2 ff02::1%eth0
PING ff02::1%eth0 (ff02::1%eth0) 56 data bytes
64 bytes from fe80::25:70ff:febc:29c6%eth0: icmp_seq=1 ttl=64 time=0.716 ms
64 bytes from fe80::1f:23ff:fee7:e9d5%eth0: icmp_seq=1 ttl=64 time=2.08 ms
64 bytes from fe80::6a:dcff:fe93:3b8a%eth0: icmp_seq=1 ttl=64 time=2.37 ms
64 bytes from fe80::9e:43ff:fe3e:caae%eth0: icmp_seq=1 ttl=64 time=2.63 ms
64 bytes from fe80::fd:f2ff:fed2:63ba%eth0: icmp_seq=1 ttl=64 time=2.64 ms
64 bytes from fe80::25:70ff:febc:29c6%eth0: icmp_seq=2 ttl=64 time=0.763 ms
64 bytes from fe80::6a:dcff:fe93:3b8a%eth0: icmp_seq=2 ttl=64 time=1.23 ms
64 bytes from fe80::1f:23ff:fee7:e9d5%eth0: icmp_seq=2 ttl=64 time=1.38 ms
64 bytes from fe80::9e:43ff:fe3e:caae%eth0: icmp_seq=2 ttl=64 time=1.39 ms
64 bytes from fe80::fd:f2ff:fed2:63ba%eth0: icmp_seq=2 ttl=64 time=1.39 ms

--- ff02::1%eth0 ping statistics ---
2 packets transmitted, 2 received, +8 duplicates, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.716/1.657/2.635/0.683 ms
```

Cada pedido rendeu cinco respostas, então dois pedidos deram `2 received, +8 duplicates`. Os cinco são,
pelos endereços link-local: `fe80::25:70ff:febc:29c6`, o próprio pc1, que é membro do grupo como todo
mundo; `fe80::1f:23ff:fee7:e9d5`, o r1; `fe80::9e:43ff:fe3e:caae`, o srv; `fe80::fd:f2ff:fed2:63ba`, o
pc2; e `fe80::6a:dcff:fe93:3b8a`, o switch. Neste laboratório o sw1 é uma bridge Linux, e a bridge tem
uma interface própria com um endereço link-local como qualquer outra; um switch não gerenciável, sem
endereço, não teria respondido.

**Um ping para `ff02::1` é o censo mais rápido de um enlace IPv6**, e ao contrário do ping de broadcast
da aula 8 ninguém precisou mudar opção nenhuma: o Linux responde por padrão a echo requests para
todos os nós. Nenhum roteador encaminha um pacote `ff02::` para fora do enlace, então esse censo só
enxerga o próprio cabo.
