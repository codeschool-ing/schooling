---
title: O tamanho que um pacote pode ter
version: 1
---

Todo enlace tem um **MTU**, *maximum transmission unit*, a unidade máxima de transmissão: o maior
pacote IP que ele leva num quadro. Na Ethernet são 1500 bytes, e o `ping` consegue testar. O `-s`
define o tamanho dos dados, e o `-M do` liga a flag **don't fragment**, não fragmentar, que proíbe
qualquer roteador de cortar o pacote em pedaços:

```
ana@laptop:~$ ip link show eth0 | head -1
158: eth0@if159: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
ana@laptop:~$ ping -c 1 -M do -s 1472 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 1472(1500) bytes of data.
1480 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.323 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.323/0.323/0.323/0.000 ms
ana@laptop:~$ ping -c 1 -M do -s 1473 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 1473(1501) bytes of data.
ping: local error: message too long, mtu=1500

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms
```

1472 bytes de dados, mais 8 de cabeçalho ICMP e 20 de cabeçalho IP, dá exatamente 1500, e passou. Um
byte a mais e o laptop se recusou até a enviar: `message too long, mtu=1500`.

Agora a linha do escritório vira o tipo que muitos escritórios pequenos têm, DSL com **PPPoE**, que
gasta 8 bytes de cada quadro com o próprio cabeçalho e deixa um MTU de **1492**. O mesmo ping de 1500
bytes:

```
ana@laptop:~$ ping -c 2 -M do -s 1472 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 1472(1500) bytes of data.
From 192.168.10.1 icmp_seq=1 Frag needed and DF set (mtu = 1492)
ping: local error: message too long, mtu=1492

--- 192.0.2.80 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1006ms

ana@laptop:~$ ip route get 192.0.2.80
192.0.2.80 via 192.168.10.1 dev eth0 src 192.168.10.20 uid 1000 
    cache expires 597sec mtu 1492 
ana@laptop:~$ tracepath -n 192.0.2.80
 1?: [LOCALHOST]                      pmtu 1500
 1:  192.168.10.1                                          0.061ms 
 1:  192.168.10.1                                          0.005ms 
 2:  192.168.10.1                                          0.006ms pmtu 1492
 2:  203.0.113.1                                           0.449ms 
 3:  198.51.100.254                                        0.023ms 
 4:  192.0.2.80                                            0.111ms reached
     Resume: pmtu 1492 hops 4 back 4 
```

A primeira linha da resposta é a importante. **O roteador não conseguia mandar o pacote adiante, não
podia cortá-lo, e avisou**: `Frag needed and DF set (mtu = 1492)`, uma mensagem ICMP vinda de
`192.168.10.1`. O laptop acreditou. O segundo ping nem saiu: `message too long, mtu=1492`. A tabela de
rotas agora guarda esse limite para este destino pelos próximos dez minutos (`expires 597sec`), e o
`tracepath` encontra a mesma coisa salto a salto: o MTU do caminho cai para 1492 no salto 2.

Essa troca é a **descoberta do MTU do caminho**, *path MTU discovery*, e ela roda sem ninguém perceber,
todo dia, em toda conexão. A próxima seção é o que acontece quando ela não consegue.
