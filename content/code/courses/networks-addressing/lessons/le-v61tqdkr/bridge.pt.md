---
title: "A bridge: o que um switch é por baixo"
version: 1
---

Antes dos switches, uma Ethernet que ficava movimentada demais era cortada em duas, e as metades
eram ligadas por uma **bridge** (ponte). Uma bridge tinha duas portas, uma para cada metade. **Ela
aprendia quais endereços MAC moravam de cada lado, lendo o endereço de origem de cada quadro, e só
passava um quadro para o outro lado quando o destino estava lá.** O tráfego entre duas máquinas da
mesma metade ficava naquela metade.

Essa descrição é o switch da aula 1, palavra por palavra, com duas portas em vez de muitas. **Um
switch é uma bridge com muitas portas**, feita para encaminhar em hardware; os padrões ainda chamam
o mecanismo de bridging, e o Linux o chama de bridge. O switch do laboratório, o sw1, é uma bridge
Linux chamada `br0` com cinco portas:

```
root@sw1:~# bridge link show
77: p1@if78: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
79: p2@if80: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
81: p3@if82: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
83: p4@if84: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
85: p8@if86: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw1:~# bridge fdb show br br0 dynamic
```

Cinco portas, `master br0`, e uma tabela de endereços aprendidos vazia. O laboratório a esvaziou
logo antes deste bloco, para você ver o aprendizado. O pc1 pinga o servidor, depois o pc2:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.213/1.213/1.213/0.000 ms
ana@pc2:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.229/1.229/1.229/0.000 ms
root@sw1:~# bridge fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 master br0 
02:fd:f2:d2:63:ba dev p2 master br0 
02:9e:43:3e:ca:ae dev p4 master br0 
```

**Três entradas, a partir de dois pings.** Os quadros do pc1 ensinaram à bridge que
`02:25:70:bc:29:c6` está em p1; os do pc2, que `02:fd:f2:d2:63:ba` está em p2; e o servidor, que
respondeu aos dois, ensinou que `02:9e:43:3e:ca:ae` está em p4. Ninguém digitou nada disso. O pc3 e
o roteador em p8 não enviaram nada nesse tempo, então a bridge ainda não sabe nada sobre eles.

`fdb` quer dizer *forwarding database*, a base de encaminhamento, o nome que a bridge dá à tabela,
e `dynamic` pede as entradas que ela aprendeu, e não as que alguém configurou.

## As entradas expiram

```
root@sw1:~# ip -d link show br0 | grep -o "ageing_time [0-9]*"
ageing_time 30000
```

**`ageing_time 30000` está em centésimos de segundo: 300 segundos, cinco minutos.** Uma entrada que
nenhum quadro renovou por esse tempo é esquecida, então uma máquina desligada de p1 e ligada em p3 é
achada no lugar novo assim que manda um quadro, e um endereço que sumiu deixa de ocupar uma linha da
tabela. A aula 1 pôs esse valor em 0 para o switch esquecer tudo na hora, e foi assim que ele imitou
um hub.

## O que uma bridge divide, e o que não divide

Uma bridge fica entre dois segmentos e **os separa em domínios de colisão diferentes**: uma colisão
de um lado nunca chega ao outro, porque a bridge recebe o quadro inteiro antes de mandá-lo adiante.
Ela **não** divide o domínio de broadcast. Um quadro para `ff:ff:ff:ff:ff:ff`, como a pergunta do
ARP, é para todo mundo, então a bridge o manda por todas as portas, e as duas metades continuam sendo
uma rede com uma faixa de endereços. A aula 18 mede os dois, e a aula 19 mostra como um switch
divide um domínio de broadcast sem roteador.

Bridges Linux não são só um truque de laboratório. Máquinas virtuais e contêineres num host chegam à
rede exatamente por esse tipo de bridge, e em muitos roteadores domésticos as portas de "switch"
atrás são ligadas por uma bridge no software do roteador.
