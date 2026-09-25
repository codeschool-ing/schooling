---
title: Camadas 1 e 2: um enlace e um endereço de hardware
version: 1
---

A camada 1 é o sinal físico: o cabo, o rádio, a luz na porta. Um terminal não vê um sinal, mas vê o
que a placa de rede faz com ele:

```
ana@laptop:~$ ip link show eth0
106: eth0@if107: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:a8:0a:14 brd ff:ff:ff:ff:ff:ff link-netns wire
ana@laptop:~$ ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0@if107       UP             52:54:00:a8:0a:14 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

As flags entre `< >` são o estado da placa. **`UP` quer dizer que a interface foi ligada, e
`LOWER_UP` quer dizer que há sinal do outro lado**: um cabo conectado a algo ligado, ou uma associação
de Wi-Fi. `UP` sem `LOWER_UP` é o cabo desconectado, e é a primeira coisa a descartar, porque nada
acima dele funciona. `mtu 1500` é o maior pacote que este enlace carrega, e a aula 2 volta a ele.
(`link-netns wire` é o laboratório aparecendo: a outra ponta deste cabo está na fiação do
laboratório.)

A camada 2 entrega um **quadro** a um dispositivo no mesmo enlace, e dá nome ao dispositivo pelo seu
**endereço MAC**: `52:54:00:a8:0a:14` para o laptop, seis bytes escritos em hexadecimal e atribuídos
à placa de rede. Um switch lê o MAC para decidir por qual porta o quadro sai. Ele não significa nada
fora do enlace, e nenhum roteador o encaminha.

O laptop sabe o endereço IP do servidor, mas um quadro precisa do MAC do servidor. Ele pergunta, com
**ARP** (*Address Resolution Protocol*). A tabela de vizinhos do laptop começa vazia, e um ping a
preenche:

```
ana@laptop:~$ ip neigh
ana@laptop:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=64 time=0.358 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.358/0.358/0.358/0.000 ms
ana@laptop:~$ ip neigh
192.168.10.10 dev eth0 lladdr 52:54:00:a8:0a:0a REACHABLE 
```

Enquanto isso, no servidor, o `tcpdump` imprimiu cada quadro que chegou:

```
ana@server:~$ sudo tcpdump -n -e -i eth0 -c 4 arp or icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:05:53.343795 52:54:00:a8:0a:14 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.10 tell 192.168.10.20, length 28
13:05:53.343817 52:54:00:a8:0a:0a > 52:54:00:a8:0a:14, ethertype ARP (0x0806), length 42: Reply 192.168.10.10 is-at 52:54:00:a8:0a:0a, length 28
13:05:53.343826 52:54:00:a8:0a:14 > 52:54:00:a8:0a:0a, ethertype IPv4 (0x0800), length 98: 192.168.10.20 > 192.168.10.10: ICMP echo request, id 21270, seq 1, length 64
13:05:53.343925 52:54:00:a8:0a:0a > 52:54:00:a8:0a:14, ethertype IPv4 (0x0800), length 98: 192.168.10.10 > 192.168.10.20: ICMP echo reply, id 21270, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Quatro quadros. No primeiro, o MAC de destino é **`ff:ff:ff:ff:ff:ff`, o endereço de broadcast, que
todo dispositivo do enlace recebe**, e a pergunta é *quem tem 192.168.10.10, avise 192.168.10.20*. Só
o servidor responde, direto para o laptop: *192.168.10.10 está em 52:54:00:a8:0a:0a*. A resposta
chegou 22 microssegundos depois da pergunta, e o ping veio em seguida, endereçado a esse MAC. A tabela
guarda a resposta como `REACHABLE`, e o próximo pacote sai sem perguntar.
