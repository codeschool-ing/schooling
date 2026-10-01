---
title: A eleição da raiz
version: 1
---

**O spanning tree transforma uma teia de cabos numa árvore**: um caminho entre quaisquer dois
switches, e nenhum laço. Ele faz isso sem desligar nada. Todos os cabos continuam conectados, e em
cada cabo redundante uma única porta é posta num estado em que não encaminha dados. Se um cabo em
uso falhar, uma porta bloqueada pode assumir. O protocolo é o **Spanning Tree Protocol** (STP),
padronizado como IEEE 802.1D, e a bridge do Linux neste laboratório implementa essa versão original.

Os switches conversam entre si em **BPDUs** (*bridge protocol data units*), quadros pequenos
enviados a um endereço multicast que todo switch com STP escuta. Por padrão um switch manda um a
cada 2 segundos, o *hello time*. Dessas mensagens saem, nesta ordem:

1. **uma ponte raiz** para a rede inteira, o switch a partir do qual todo caminho é medido;
2. em cada um dos outros switches, **uma porta raiz**, o caminho mais barato até a raiz;
3. em cada cabo, **uma porta designada**, a ponta que encaminha o tráfego naquele cabo;
4. toda porta que sobra **bloqueia**.

Esta seção é o primeiro passo. A próxima trata dos outros três.

## Ligando o protocolo

O spanning tree foi ligado nos três switches, e o cabo do `sw3` ao `sw1`, o que causou a tempestade,
foi conectado de volta. Na mesma hora o `sw1` foi cauteloso com ele:

```
root@sw1:~# ip link set br0 type bridge stp_state 1
root@sw2:~# ip link set br0 type bridge stp_state 1
root@sw3:~# ip link set br0 type bridge stp_state 1
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state listening priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
```

A `p3` tem sinal de novo (`LOWER_UP`) e está em `state listening`: troca BPDUs e não encaminha dados
enquanto a eleição acontece. Quarenta segundos depois, os três switches tinham chegado a um acordo:

```
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw2:~# bridge link show
461: p1@if462: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
464: p3@if463: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 2 
469: p10@if470: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw3:~# bridge link show
463: p2@if464: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
466: p1@if465: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
471: p10@if472: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
ana@pc1:~$ ping -c 2 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.643/4.118/6.594/2.475 ms
```

Oito portas encaminham e **uma bloqueia: a `p3` do `sw2`, a ponta dele no cabo para o `sw3`**. O
triângulo agora é uma linha, `sw2`–`sw1`–`sw3`, e o `pc1` alcança o `pc3` sem tempestade. Nada mudou
nos PCs.

## O ID de ponte, e por que o menor ganha

Todo switch tem um **ID de ponte** (*bridge ID*): uma prioridade de 2 bytes seguida de um endereço
MAC do switch. O kernel guarda tudo isso em arquivos:

```
root@sw1:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost
bridge_id:8000.026adc933b8a
root_id:8000.026adc933b8a
root_port:0
root_path_cost:0
root@sw2:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost
bridge_id:8000.02e0779de790
root_id:8000.026adc933b8a
root_port:1
root_path_cost:2
root@sw3:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port root_path_cost
bridge_id:8000.02a59d312a8c
root_id:8000.026adc933b8a
root_port:1
root_path_cost:2
```

Leia `8000.026adc933b8a` em duas partes. `8000` é a prioridade em hexadecimal, **32768, o padrão**,
e todo switch aqui tem esse valor. Depois do ponto vem o endereço MAC sem os dois-pontos. Cada switch
começa se declarando raiz, e **o menor ID de ponte ganha**: comparam-se primeiro as prioridades e,
quando empatam, os endereços MAC. As três prioridades são iguais, então os MACs decidem, e `02:6a:…`
é menor que `02:a5:…` e `02:e0:…`. Agora todo switch dá a mesma resposta em `root_id`, que é o
próprio ID do `sw1`.

O `sw1` é a raiz, então não tem porta raiz (`root_port:0`) e a distância dele até a raiz é
`root_path_cost:0`. Os outros dois chegam a ele pela porta número 1, com custo 2. **O custo é somado
por porta ao longo do caminho**, e toda porta neste laboratório custa 2 (o `cost 2` no fim de cada
linha do `bridge link show`), então 2 quer dizer um cabo de distância.

## A raiz que ninguém escolheu

É tentador achar que a raiz é o switch maior ou mais central. **Com as prioridades padrão, a raiz é
o switch que tiver o menor endereço MAC**, e nada num MAC diz que o switch por trás dele é rápido ou
bem posicionado. Um switch de acesso antigo num armário pode ganhar a eleição, e então o tráfego da
rede inteira se organiza em torno daquele armário. A seção sobre falhas desta lição muda a raiz
alterando uma prioridade, que é como uma rede escolhe a raiz de propósito.
