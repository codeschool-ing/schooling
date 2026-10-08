---
title: iperf3, e o que um teste de velocidade mede
version: 1
---

Um ping diz que um caminho existe; não diz nada sobre quanto ele leva. **O iperf3 mede vazão entre duas
máquinas que você controla**: um servidor que escuta, na porta 5201 a menos que se diga outra, e um
cliente que manda o mais rápido que o caminho permite durante um tempo definido. Para estas rodadas o
enlace de `hq` para o provedor foi moldado em 20 Mbit/s, do jeito que as aulas 18 e 20 fizeram,
`sudo tc qdisc add dev eth1 root tbf rate 20mbit burst 32kb latency 50ms` em `hq`, e o web1 foi o
servidor, o `iperf3 -s` que o `netlab.sh` inicia em todo servidor web:

```
ana@web1:~$ ss -tlnp | grep 5201
LISTEN 0      4096         0.0.0.0:5201       0.0.0.0:*          
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5
Connecting to host 192.0.2.21, port 5201
[  5] local 192.168.10.20 port 57774 connected to 192.0.2.21 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  3.12 MBytes  26.2 Mbits/sec  154   14.1 KBytes       
[  5]   1.00-2.00   sec  2.12 MBytes  17.8 Mbits/sec    0   17.0 KBytes       
[  5]   2.00-3.00   sec  2.25 MBytes  18.9 Mbits/sec    0   14.1 KBytes       
[  5]   3.00-4.00   sec  2.25 MBytes  18.9 Mbits/sec    0   14.1 KBytes       
[  5]   4.00-5.00   sec  2.25 MBytes  18.9 Mbits/sec    0   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-5.00   sec  12.0 MBytes  20.1 Mbits/sec  154             sender
[  5]   0.00-5.01   sec  11.4 MBytes  19.1 Mbits/sec                  receiver

iperf Done.
```

O primeiro segundo mostra 26.2 Mbit/s e **154 retransmissões**: o TCP achando o limite, mandando mais
rápido do que o shaper deixa passar até pacotes serem descartados. Daí em diante ele fica entre 17.8 e
18.9 sem nenhuma. O resumo tem duas linhas, e **a do receptor é a que se cita**: 19.1 Mbit/s é o que
chegou, enquanto 20.1 é o que o emissor empurrou. A diferença para 20 é em parte cabeçalho, que o shaper
conta e o iperf3 não.

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -R | tail -n 4
[  5]   0.00-5.00   sec  1.93 GBytes  3.31 Gbits/sec  1888             sender
[  5]   0.00-5.00   sec  1.93 GBytes  3.31 Gbits/sec                  receiver

iperf Done.
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -P 4 | tail -n 4
[SUM]   0.00-5.00   sec  12.4 MBytes  20.8 Mbits/sec  819             sender
[SUM]   0.00-5.03   sec  11.2 MBytes  18.7 Mbits/sec                  receiver

iperf Done.
```

`-R` inverte o sentido: o servidor manda e o laptop recebe. **3.31 Gbit/s, mais de cento e sessenta
vezes o upload.** O shaper fica no que sai de `hq` para o provedor, então o download só foi limitado por
um computador copiando pacotes entre os próprios namespaces. Enlaces de acesso de verdade muitas vezes são
assimétricos de propósito: muitos planos de cabo e fibra vendem várias vezes mais download que upload, e
**um teste num sentido não diz nada sobre o outro**.

`-P 4` roda quatro fluxos ao mesmo tempo, e juntos eles dão 20.8 Mbit/s enviados e 18.7 recebidos, os
mesmos 20 de um fluxo só. Fluxos paralelos ajudam quando uma única conexão TCP é contida pela própria
janela num caminho longo; **contra um shaper, que limita o total, eles só o dividem**.

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -u -b 10M | tail -n 4
[  5]   0.00-5.00   sec  5.96 MBytes  10.0 Mbits/sec  0.000 ms  0/4316 (0%)  sender
[  5]   0.00-5.00   sec  5.96 MBytes  10.0 Mbits/sec  0.031 ms  0/4316 (0%)  receiver

iperf Done.
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 -u -b 30M | tail -n 4
[  5]   0.00-5.00   sec  17.9 MBytes  30.0 Mbits/sec  0.000 ms  0/12947 (0%)  sender
[  5]   0.00-5.06   sec  11.8 MBytes  19.5 Mbits/sec  0.469 ms  4432/12945 (34%)  receiver

iperf Done.
```

Com `-u` o iperf3 manda UDP na taxa que o `-b` pede, e o UDP não recua. A 10 Mbit/s os 4316 datagramas
chegaram todos, com 0.031 ms de jitter. A 30 Mbit/s o emissor mandou 30.0, o receptor recebeu 19.5, e
**4432 de 12945 datagramas se perderam, 34%**. O excesso é descartado no gargalo, e o jitter subiu para
0.469 ms porque os datagramas que sobreviveram esperaram na fila do shaper. Isso é uma chamada de vídeo
num enlace cheio: nada desacelera, pedaços somem e o resto chega desigual.

## Um teste de velocidade público

Um teste de velocidade no navegador é a mesma medida contra um servidor que outra pessoa mantém. Nenhum
foi rodado para esta aula, porque o laboratório não tem saída para a internet, mas os motivos para o
número dele diferir do contrato decorrem das rodadas acima:

- Ele mede o caminho inteiro, inclusive o seu Wi-Fi, que é o gargalo em muitas casas e que a aula 6
  mostrou ser tempo de ar compartilhado.
- Ele mede até um servidor, em geral perto do seu provedor, então diz pouco sobre um site do outro
  lado do oceano.
- Ele conta dados, e o contrato conta a linha, cabeçalhos incluídos, então até uma linha perfeita
  testa alguns por cento abaixo da taxa.
- Ele em geral abre vários fluxos e descarta os primeiros segundos, o que esconde justamente a subida
  que a primeira linha da rodada do laboratório mostrou.

Para uma reclamação ao provedor, um teste de velocidade é um começo. **Para uma afirmação sobre um enlace
que você administra, o iperf3 entre duas máquinas nas pontas dele mede aquele enlace e mais nada.**
