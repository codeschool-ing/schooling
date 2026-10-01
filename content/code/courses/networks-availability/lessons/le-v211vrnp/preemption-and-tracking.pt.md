---
title: Pegando o endereço de volta, e entregando-o
version: 1
---

Quando o cabo de `hq` volta, `hq2` é o master e tudo funciona. Se `hq` deve agora pegar o endereço de volta
é uma escolha, chamada **preempção**, e o padrão do VRRP é sim: um roteador de prioridade maior que volta
assume de novo. O keepalived segue o padrão, e o laptop pegou o que `hq` manda quando faz isso. O filtro
guarda só o ARP vindo do endereço de hardware de `hq`:

```
ana@laptop:~$ sudo tcpdump -n -t -e -i eth0 -c 2 arp and ether src 52:54:00:a8:0a:02
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
52:54:00:a8:0a:02 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.1 (ff:ff:ff:ff:ff:ff) tell 192.168.10.1, length 28
52:54:00:a8:0a:02 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.1 (ff:ff:ff:ff:ff:ff) tell 192.168.10.1, length 28
2 packets captured
5 packets received by filter
0 packets dropped by kernel
ana@hq:~$ grep -E "Entering" /run/keepalived.log
Mon Sep 28 18:10:55 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:59 2026: (office) Entering MASTER STATE
Mon Sep 28 18:11:06 2026: (office) Entering FAULT STATE
Mon Sep 28 18:11:12 2026: (office) Entering BACKUP STATE
Mon Sep 28 18:11:16 2026: (office) Entering MASTER STATE
ana@laptop:~$ ip neigh show 192.168.10.1
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:02 STALE 
```

O log de `hq` tem a história inteira da tarde dele. Master às 18:10:59; `FAULT` às 18:11:06, quando o cabo
saiu; de volta a `BACKUP` às 18:11:12, quando ele voltou; master de novo às 18:11:16. Ele não assumiu no
segundo em que o cabo voltou. Voltou como backup, escutou, e virou master quatro segundos depois pelo
relógio de segundos inteiros do log, o mesmo tipo de espera da inicialização.

## ARP gratuito

Os dois pacotes que ele mandou no momento em que assumiu são estranhos. São pedidos ARP, em broadcast para
`ff:ff:ff:ff:ff:ff`, perguntando `who-has 192.168.10.1` e assinados `tell 192.168.10.1`: **um roteador
perguntando à LAN inteira quem tem o próprio endereço dele**. Ninguém deve responder. O que importa é o
endereço de hardware de quem manda, dentro do pedido, `52:54:00:a8:0a:02`. Todo host que já tem uma
entrada ARP para `192.168.10.1` a atualiza para o MAC de quem mandou, e a entrada do laptop voltou para o
`:02` de `hq` sem o laptop ter perguntado nada. Isso é um **ARP gratuito** (gratuitous ARP), e é assim que
o novo master de um failover redireciona todos os hosts com um só broadcast, em vez de esperar os caches
expirarem. `STALE` só quer dizer que a entrada não foi confirmada recentemente.

## O custo de pegar de volta

Preempção quer dizer que **o escritório passa por uma segunda troca quando o roteador que falhou volta.** É uma troca curta, já que `hq` se anuncia na hora em vez de esperar um silêncio. Nenhum ping estava rodando durante essa volta, então ela não foi medida. Faz sentido quando `hq` é o roteador melhor, com um enlace
mais rápido ou uma máquina maior. Quando os dois são iguais, compra uma interrupção e mais nada. O `nopreempt` do keepalived a desliga, ou o `preempt_delay` faz o roteador que volta esperar, para que um
que fica oscilando não arraste o gateway junto.

## Tracking: entregando o endereço de propósito

Um roteador pode estar vivo na LAN e inútil. Se `hq` perde o enlace com o provedor, continua respondendo
VRRP no `eth0`, continua ganhando a eleição com prioridade 150, e todo host continua mandando para ele um
tráfego que ele não tem para onde mandar. **Um gateway sem saída é pior que um morto**, porque um morto
pelo menos teria sido substituído.

É para isso que serve o `track_interface` da configuração: `eth1` é o enlace de `hq` com o provedor, e se
ele cair, o keepalived põe a instância em `FAULT` e abre mão do endereço. O enlace do provedor foi
derrubado enquanto `hq` era master:

```
ana@hq:~$ grep -E "eth1|FAULT|Entering" /run/keepalived.log | tail -n 3
Mon Sep 28 18:11:16 2026: (office) Entering MASTER STATE
Mon Sep 28 18:11:16 2026: Netlink reports eth1 down
Mon Sep 28 18:11:16 2026: (office) Entering FAULT STATE
ana@hq2:~$ ip -br addr show eth0
eth0@if1240      UP             192.168.10.3/24 192.168.10.1/24 
ana@laptop:~$ ping -c 2 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.214 ms
64 bytes from 192.0.2.21: icmp_seq=2 ttl=62 time=0.118 ms

--- 192.0.2.21 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1006ms
rtt min/avg/max/mdev = 0.118/0.166/0.214/0.048 ms
```

No mesmo segundo, pelo relógio do log, em que `hq` voltou a ser master, ele informou `eth1` fora do ar e
foi para `FAULT`. **`hq2` tem `192.168.10.1` de novo, e o ping do laptop passa por ele sem perda**, embora
`hq` esteja rodando e o cabo dele na LAN esteja bom. Quando o enlace do provedor voltou, `hq` passou pelos
mesmos passos de antes:

```
ana@hq:~$ grep -E "eth1|FAULT|Entering" /run/keepalived.log | tail -n 3
Mon Sep 28 18:11:22 2026: Netlink reports eth1 up
Mon Sep 28 18:11:22 2026: (office) Entering BACKUP STATE
Mon Sep 28 18:11:26 2026: (office) Entering MASTER STATE
```

O enlace de `hq` subiu às 18:11:22, ele voltou como backup e pegou o endereço de volta às 18:11:26.

Os roteadores da Cisco rastreiam de outro jeito, e isso confunde muita gente: lá uma interface rastreada
costuma **baixar a prioridade** de um valor fixo em vez de sair da eleição. O parceiro então só assume se
tiver permissão para fazer preempção, então uma regra que baixa `hq` para 90 não faz nada enquanto `hq2`
estiver com a preempção desligada.
