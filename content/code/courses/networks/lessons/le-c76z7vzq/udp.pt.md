---
title: UDP: um pacote, e nenhuma promessa
version: 1
---

O UDP manda um pacote para uma porta e é só. Sem handshake, sem confirmação, sem retransmissão. Uma
pergunta de DNS do laptop, vista no resolver:

```
ana@resolver:~$ sudo tcpdump -n -i eth0 -c 2 udp port 53 and host 203.0.113.2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:08.492146 IP 203.0.113.2.56951 > 198.51.100.53.53: 59776+ [1au] A? www.example.com. (56)
13:27:08.492635 IP 198.51.100.53.53 > 203.0.113.2.56951: 59776 1/0/1 A 192.0.2.80 (60)
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**Dois pacotes, a troca inteira: uma pergunta e uma resposta.** `A? www.example.com.` pede o endereço;
`A 192.0.2.80` é ele, e `1/0/1` conta os registros da resposta (a aula 4 lê o resto). Por TCP, a mesma
pergunta custaria um handshake antes, três pacotes antes de um único byte de pergunta. Se a resposta se
perde, ninguém no kernel percebe: o próprio programa, aqui o `dig`, espera alguns segundos e pergunta
de novo.

Sem handshake também quer dizer sem resposta clara quando se testa uma porta. O `nc -u` manda um pacote
e conta o que conseguiu saber:

```
ana@laptop:~$ nc -zuv -w 1 198.51.100.53 53
Connection to 198.51.100.53 53 port [udp/domain] succeeded!
```

```
ana@laptop:~$ nc -zuv -w 1 192.0.2.80 9999; echo "exit status $?"
exit status 1
```

```
ana@www:~$ sudo tcpdump -n -i eth0 -c 2 udp port 9999 or icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:11.567578 IP 203.0.113.2.33553 > 192.0.2.80.9999: UDP, length 1
13:27:11.567591 IP 192.0.2.80 > 203.0.113.2: ICMP 192.0.2.80 udp port 9999 unreachable, length 37
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

Uma porta UDP fechada só se sabe porque o sistema do servidor devolveu um ICMP *port unreachable*,
porta inalcançável, e o nc percebeu e saiu com status 1, em silêncio. Agora uma porta que um firewall
descarta, seção 07:

```
ana@laptop:~$ nc -zuv -w 1 192.0.2.80 9998; echo "exit status $?"
Connection to 192.0.2.80 9998 port [udp/*] succeeded!
exit status 0
```

**`succeeded`, para uma porta em que nada escuta.** O pacote sumiu, nenhum ICMP voltou, e para o nc o
silêncio é idêntico a um servidor que recebeu o pacote e escolheu não responder. No UDP, "aberta" num
teste de porta quer dizer só "ninguém disse não". O teste de verdade é fazer ao serviço uma pergunta de
verdade: `dig` para DNS, como a aula 4 faz.
