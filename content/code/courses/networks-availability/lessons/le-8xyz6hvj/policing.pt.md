---
title: Um policer no provedor
version: 1
---

O shaper foi removido, fora da tela, e o limite foi para onde um provedor o poria: o roteador do
provedor, no tráfego que chega de `hq`. É uma regra de `nftables` com a mesma taxa e o mesmo balde, e um
final diferente, `drop`:

```
ana@isp:~$ sudo nft add table ip contract && sudo nft add chain ip contract police "{ type filter hook forward priority 0; }"
ana@isp:~$ sudo nft add rule ip contract police iifname eth0 ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter drop
```

`limit rate over 625 kbytes/second burst 16 kbytes` casa com o que passar do balde, e `counter drop` o
conta e o joga fora. O que cabe passa intacto. O mesmo upload:

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 8
Connecting to host 192.0.2.21, port 5201
[  5] local 192.168.10.20 port 47016 connected to 192.0.2.21 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  2.50 MBytes  20.9 Mbits/sec  330   45.2 KBytes       
[  5]   1.00-2.00   sec   640 KBytes  5.24 Mbits/sec    1   63.6 KBytes       
[  5]   2.00-3.00   sec   640 KBytes  5.24 Mbits/sec  283   48.1 KBytes       
[  5]   3.00-4.00   sec   640 KBytes  5.24 Mbits/sec    5   5.66 KBytes       
[  5]   4.00-5.00   sec   640 KBytes  5.24 Mbits/sec  304   59.4 KBytes       
[  5]   5.00-6.00   sec   640 KBytes  5.24 Mbits/sec    0   36.8 KBytes       
[  5]   6.00-7.00   sec   640 KBytes  5.24 Mbits/sec  323    129 KBytes       
[  5]   7.00-8.00   sec   640 KBytes  5.24 Mbits/sec   91   31.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-8.00   sec  6.88 MBytes  7.21 Mbits/sec  1337             sender
[  5]   0.00-8.00   sec  5.12 MBytes  5.37 Mbits/sec                  receiver

iperf Done.
```

**A coluna de retransmissões nunca se acomoda.** 330 no primeiro segundo, depois 1, 283, 5, 304, 0, 323 e
91, **1337 ao todo**, contra 248 do shaper. A coluna `Cwnd` mostra por quê: 45,2, 63,6, 48,1, **5,66**,
59,4, 36,8, **129**, 31,1 KBytes. O TCP aumenta a janela até o policer descartar uma sequência de pacotes,
corta, e aumenta de novo; sem nada que absorva uma rajada, toda subida termina numa perda. O receptor
ainda assim recebeu **5,37 Mbits/sec**. A regra do policer e a do shaper estão escritas em ferramentas e
unidades diferentes e não são exatamente a mesma taxa, então leia as duas linhas do receptor como
vizinhas, não como uma disputa.

O ping, no segundo terminal como antes:

```
ana@laptop:~$ sleep 2; ping -c 5 -q 192.0.2.21 | tail -n 2
5 packets transmitted, 5 received, 0% packet loss, time 4085ms
rtt min/avg/max/mdev = 0.054/0.070/0.081/0.009 ms
```

**0,070 ms.** Com o upload rodando, um ping passou como se o enlace estivesse ocioso, porque um policer
não tem fila: um pacote ou cabe no balde e sai na hora, ou não cabe e some. Esses cinco pings tiveram a
sorte de encontrar fichas. Um pacote de voz que chegasse durante uma das rajadas do upload não seria
atrasado; seria descartado, e um pacote de voz perdido é um buraco na frase de alguém.

A contagem do próprio policer:

```
ana@isp:~$ sudo nft list chain ip contract police
table ip contract {
	chain police {
		type filter hook forward priority filter; policy accept;
		iifname "eth0" ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter packets 1335 bytes 2002500 drop
	}
}
```

**1335 pacotes, 2.002.500 bytes**, exatamente 1500 bytes cada, o maior pacote que o enlace leva. Os
descartes caíram nos pacotes de tamanho máximo do upload, e são dois a menos que as 1337 retransmissões
do emissor, o que é o mais perto que dois contadores em dois programas diferentes vão chegar.

Então a mesma taxa, segurada de dois jeitos, deu sintomas opostos: **o shaper custou 22 ms de atraso e
quase nenhuma perda, o policer não custou atraso nenhum e custou um fluxo constante de perdas**. Qual dos
dois um enlace deve ter depende de quem é o dono dele.
