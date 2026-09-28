---
title: Um shaper no uplink de hq
version: 1
---

Primeiro, a velocidade do uplink do laboratório sem nada no caminho. Um upload com `iperf3` do laptop para
`web1`:

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 3 | tail -n 4
[  5]   0.00-3.00   sec  1.02 GBytes  2.91 Gbits/sec  513             sender
[  5]   0.00-3.00   sec  1.02 GBytes  2.91 Gbits/sec                  receiver

iperf Done.
```

**2,91 Gbits/sec**, que é um computador copiando memória entre os próprios namespaces de rede, não um
enlace que alguém compraria; as 513 retransmissões são o TCP achando até esse limite ao passar dele.
Agora `hq` ganha um shaper na `eth1`, o token bucket filter do `tc`, o `tbf`, com a taxa e o balde da
seção anterior, e o mesmo upload roda por oito segundos:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root tbf rate 5mbit burst 16kb latency 50ms
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 8
Connecting to host 192.0.2.21, port 5201
[  5] local 192.168.10.20 port 51978 connected to 192.0.2.21 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.75 MBytes  14.7 Mbits/sec  248   14.1 KBytes       
[  5]   1.00-2.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   2.00-3.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   3.00-4.00   sec   640 KBytes  5.25 Mbits/sec    0   17.0 KBytes       
[  5]   4.00-5.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   5.00-6.00   sec   640 KBytes  5.24 Mbits/sec    0   17.0 KBytes       
[  5]   6.00-7.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
[  5]   7.00-8.00   sec   640 KBytes  5.24 Mbits/sec    0   14.1 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-8.00   sec  6.12 MBytes  6.42 Mbits/sec  248             sender
[  5]   0.00-8.02   sec  4.50 MBytes  4.70 Mbits/sec                  receiver

iperf Done.
```

Leia as colunas um segundo de cada vez. **No primeiro segundo o TCP enviou demais e perdeu 248
pacotes**: ele começa rápido, a fila do shaper passou do limite e o excesso foi descartado. Daí em diante
a coluna de retransmissões marca **0 por sete segundos**. A conexão se acomodou na taxa, e nada precisou
ser jogado fora, porque o shaper segurou cada pacote até as fichas dele chegarem.

Duas linhas no fim discordam, e é no receptor que se deve acreditar. O emissor conta o que o programa
escreveu no socket, incluindo 1,75 MBytes do primeiro segundo que ainda estavam na fila, então os
**6,42 Mbits/sec** dele não são uma velocidade a que algo viajou. O receptor conta o que chegou: **4,70
Mbits/sec**. Fica abaixo de 5 por um motivo honesto. O shaper conta quadros Ethernet inteiros, 1514
bytes, e cada um leva 1448 bytes do arquivo depois dos cabeçalhos IP e TCP e das opções deles, então o
máximo que o arquivo alcança é 5 × 1448 ÷ 1514, uns **4,78 Mbit/s**. A coluna por segundo, por sua vez, é
contada no emissor, nos blocos que o `iperf3` escreve, e é por isso que marca um `640 KBytes` constante.

## O que a fila custa

Um shaper tira a perda acrescentando espera, e a espera dá para medir. Este ping rodou num segundo
terminal, iniciado junto com o upload e dois segundos depois do início dele, como o próprio `sleep 2` diz:

```
ana@laptop:~$ sleep 2; ping -c 5 -q 192.0.2.21 | tail -n 2
5 packets transmitted, 5 received, 0% packet loss, time 4007ms
rtt min/avg/max/mdev = 20.932/21.989/22.950/0.805 ms
```

**22 ms em média**, contra 0,08 ms num enlace ocioso na aula 18. Isso é a fila, e as colunas do próprio
upload explicam. A coluna `Cwnd` diz que o TCP manteve uns **14,1 KBytes** em trânsito, e em regime isso
é mais ou menos o que fica na fila do shaper: 14,1 × 1024 × 8 = 115.507 bits, que a 5.000.000 de bits
por segundo levam **23 ms** para sair. O ping esperou atrás da janela do upload.

O shaper guarda o próprio placar:

```
ana@hq:~$ tc -s qdisc show dev eth1
qdisc tbf 8012: root refcnt 5 rate 5Mbit burst 16Kb lat 50ms 
 Sent 5048683 bytes 3356 pkt (dropped 248, overlimits 10246 requeues 0) 
 backlog 0b 0p requeues 0
```

`dropped 248`, as perdas do primeiro segundo, e o mesmo número das retransmissões. `overlimits 10246`
conta as vezes em que um pacote estava pronto e o balde não, que é o shaper fazendo o trabalho dele, não
um defeito. `backlog 0b 0p` é a fila depois do fim do upload: vazia.
