---
title: Puxando o cabo e medindo o buraco
version: 1
---

Um failover é tão bom quanto o buraco que deixa, e um buraco pode ser medido. O laptop pinga `web1` no data
center, depois do gateway, cinco vezes por segundo: `-i 0.2`. O `-D` põe um carimbo de tempo na frente de cada linha, em segundos desde 1970. O `-O` imprime uma linha para cada resposta que não voltou até a
saída do próximo ping, então uma resposta que falta aparece como uma linha, e não como nada. Pouco mais de
dois segundos depois do início, o cabo de `hq` para a LAN foi puxado. O cabo é o par que o `netlab.sh`
chamou de `hq-hq`, a porta de `hq` no switch da matriz, e puxá-lo é derrubar essa ponta, na máquina
virtual: `sudo ip -n wire link set hq-hq down`. Comece o ping em `laptop`, depois puxe o cabo:

```
ana@laptop:~$ ping -D -O -i 0.2 -c 40 -W 1 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
[1790629864.207277] 64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.493 ms
[1790629864.408908] 64 bytes from 192.0.2.21: icmp_seq=2 ttl=62 time=0.115 ms
[1790629864.612831] 64 bytes from 192.0.2.21: icmp_seq=3 ttl=62 time=0.084 ms
[1790629864.816783] 64 bytes from 192.0.2.21: icmp_seq=4 ttl=62 time=0.086 ms
[1790629865.020829] 64 bytes from 192.0.2.21: icmp_seq=5 ttl=62 time=0.103 ms
[1790629865.224819] 64 bytes from 192.0.2.21: icmp_seq=6 ttl=62 time=0.089 ms
[1790629865.428812] 64 bytes from 192.0.2.21: icmp_seq=7 ttl=62 time=0.082 ms
[1790629865.632824] 64 bytes from 192.0.2.21: icmp_seq=8 ttl=62 time=0.088 ms
[1790629865.836849] 64 bytes from 192.0.2.21: icmp_seq=9 ttl=62 time=0.097 ms
[1790629866.040810] 64 bytes from 192.0.2.21: icmp_seq=10 ttl=62 time=0.081 ms
[1790629866.244818] 64 bytes from 192.0.2.21: icmp_seq=11 ttl=62 time=0.086 ms
[1790629866.448808] 64 bytes from 192.0.2.21: icmp_seq=12 ttl=62 time=0.085 ms
[1790629866.652789] 64 bytes from 192.0.2.21: icmp_seq=13 ttl=62 time=0.084 ms
[1790629867.060772] no answer yet for icmp_seq=14
[1790629867.264684] no answer yet for icmp_seq=15
[1790629867.468663] no answer yet for icmp_seq=16
[1790629867.672731] no answer yet for icmp_seq=17
[1790629867.876713] no answer yet for icmp_seq=18
[1790629868.080739] no answer yet for icmp_seq=19
[1790629868.284710] no answer yet for icmp_seq=20
[1790629868.488851] no answer yet for icmp_seq=21
[1790629868.692784] no answer yet for icmp_seq=22
[1790629868.896701] no answer yet for icmp_seq=23
[1790629869.100749] no answer yet for icmp_seq=24
[1790629869.304671] no answer yet for icmp_seq=25
[1790629869.508741] no answer yet for icmp_seq=26
[1790629869.712834] no answer yet for icmp_seq=27
[1790629869.916772] no answer yet for icmp_seq=28
[1790629869.916964] 64 bytes from 192.0.2.21: icmp_seq=29 ttl=62 time=0.156 ms
[1790629870.120873] 64 bytes from 192.0.2.21: icmp_seq=30 ttl=62 time=0.078 ms
[1790629870.324802] 64 bytes from 192.0.2.21: icmp_seq=31 ttl=62 time=0.090 ms
[1790629870.528765] 64 bytes from 192.0.2.21: icmp_seq=32 ttl=62 time=0.079 ms
[1790629870.732824] 64 bytes from 192.0.2.21: icmp_seq=33 ttl=62 time=0.092 ms
[1790629870.936905] 64 bytes from 192.0.2.21: icmp_seq=34 ttl=62 time=0.121 ms
[1790629871.140871] 64 bytes from 192.0.2.21: icmp_seq=35 ttl=62 time=0.081 ms
[1790629871.344805] 64 bytes from 192.0.2.21: icmp_seq=36 ttl=62 time=0.087 ms
[1790629871.548916] 64 bytes from 192.0.2.21: icmp_seq=37 ttl=62 time=0.155 ms
[1790629871.752815] 64 bytes from 192.0.2.21: icmp_seq=38 ttl=62 time=0.091 ms
[1790629871.956922] 64 bytes from 192.0.2.21: icmp_seq=39 ttl=62 time=0.108 ms
[1790629872.160908] 64 bytes from 192.0.2.21: icmp_seq=40 ttl=62 time=0.109 ms

--- 192.0.2.21 ping statistics ---
40 packets transmitted, 25 received, 37.5% packet loss, time 7954ms
rtt min/avg/max/mdev = 0.078/0.112/0.493/0.080 ms
```

Doze respostas chegam com cerca de 0,2 segundo entre elas, e a décima terceira em `1790629866.652789`.
Depois quinze pings seguidos, do 14 ao 28, ficam sem resposta. A resposta 29 chega em `1790629869.916964`.
**O buraco entre a última resposta antes da falha e a primeira depois dela é de 3,264 segundos**, e o
resumo do próprio ping concorda pelo outro lado: 40 enviados, 25 recebidos, 37,5% de perda, que são esses
quinze.

Os dois carimbos são 18:11:06,65 e 18:11:09,92 no relógio da rede, horário de São Paulo, e os logs
dos dois roteadores põem as próprias linhas dentro dessa janela:

```
ana@hq2:~$ grep -E "Entering" /run/keepalived.log
Mon Sep 28 18:10:54 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:58 2026: (office) Entering MASTER STATE
Mon Sep 28 18:10:59 2026: (office) Entering BACKUP STATE
Mon Sep 28 18:11:09 2026: (office) Entering MASTER STATE
ana@laptop:~$ ip neigh show 192.168.10.1
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:03 DELAY 
```

`hq2` virou master às 18:11:09, o mesmo segundo em que a resposta 29 voltou. O log de `hq`, mostrado na
próxima seção, diz que ele entrou em `FAULT` às 18:11:06, o segundo em que o cabo saiu: um roteador cuja
interface da LAN caiu não consegue atender essa LAN, então o keepalived abre mão do endereço na hora.

## Por que 3,26 e não 3,61

A seção anterior calculou o master down interval de `hq2` em cerca de 3,61 segundos, e o buraco medido é
menor. **O backup conta a partir do último anúncio que ouviu, não a partir da falha.** `hq` anunciava uma
vez por segundo, então o último anúncio dele saiu entre zero e um segundo antes de o cabo ser puxado, e os 3,61 segundos de `hq2` já corriam havia esse tanto. O buraco que um host vê fica, portanto, entre
cerca de 2,61 e 3,61 segundos, mais o instante que o laptop leva para saber para onde o endereço foi, e
3,264 cai dentro disso. Os mesmos timers dão um buraco diferente cada vez que o teste é repetido.

Nenhum enlace do laboratório tem atraso. Cada ida e volta do ping é um computador falando com ele mesmo,
de 0,078 a 0,493 milissegundo, então nada dos 3,264 segundos é a rede. **É tudo espera**: o tempo que o
VRRP leva para ter certeza de que um silêncio quer dizer uma morte.

## O lado do laptop

O último comando mostra o que mudou para o laptop: a entrada ARP dele para `192.168.10.1` agora tem
`52:54:00:a8:0a:03`, o endereço de hardware de `hq2`, onde antes da falha tinha o `:02` de `hq`. O laptop
não fez nada para isso. Continuava mandando para o mesmo endereço de gateway, e alguma coisa lhe disse que
esse endereço agora morava em outro MAC. **No modo padrão do keepalived o novo master se anuncia com ARP
gratuito**, e a próxima seção captura esse anúncio quando `hq` volta.

Quinze pings perdidos também são um aviso sobre como um failover parece visto de cima. Uma conexão TCP
teria retransmitido para dentro do buraco e seguido em frente, mais lenta por um instante. Uma chamada de
voz teria perdido três segundos de fala. **Um buraco de três segundos é invisível para uma página web e bem
audível numa ligação**, e é por isso que existem timers abaixo de um segundo, e por isso a aula 14
perguntou quanto eles custam.
