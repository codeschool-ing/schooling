---
title: Mudando a raiz, e perdendo um cabo
version: 1
---

A árvore não é fixa. Ela é recalculada sempre que algo muda, e duas mudanças importam na prática:
**um administrador escolhendo outra raiz, e um cabo falhando**. A primeira é deliberada e a segunda
é a razão de o spanning tree existir. As duas foram feitas no laboratório.

## Escolhendo a raiz com uma prioridade

A prioridade é a parte do ID de ponte que uma pessoa define. Baixá-la num switch faz esse switch
ganhar a eleição seja qual for o endereço MAC dele. Aqui ela foi do padrão 32768 para 4096 no `sw3`:

```
root@sw3:~# ip link set br0 type bridge priority 4096
root@sw3:~# cd /sys/class/net/br0/bridge && grep . bridge_id root_id root_port
bridge_id:1000.02a59d312a8c
root_id:1000.02a59d312a8c
root_port:0
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw2:~# bridge link show
461: p1@if462: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 2 
464: p3@if463: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
469: p10@if470: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
```

`1000` é 4096 em hexadecimal, e o ID de ponte do `sw3` agora também é o ID da raiz: **o `sw3` é a
raiz**. A porta bloqueada mudou também. Agora o cabo mais longe da raiz é `sw1`–`sw2`. As duas pontas
dele estão a um cabo do `sw3`, o custo empata de novo, e o ID de ponte menor do `sw1` faz da `p2` do
`sw1` a porta designada, então **o `sw2` bloqueia a `p1`** desta vez e encaminha pela `p3`, a porta
que antes estava bloqueada.

Em muitos switches a prioridade só pode ser definida em passos de 4096, e o motivo está nos mesmos
dois bytes: os 12 bits de baixo carregam um número de VLAN, para que um switch possa rodar uma árvore
por VLAN. A seção sobre o spanning tree rápido desta lição volta a isso.

## Um cabo falha

Para o segundo teste a raiz voltou para o `sw1` (prioridade 32768 no `sw3` de novo, e depois uma
espera para a árvore se acomodar), o que pôs a `p3` do `sw2` de volta em `blocking`. No `pc2`, foi
iniciado um ping para o `pc1`, um pacote por segundo durante 60 segundos. Dois segundos depois o cabo
entre `sw1` e `sw2` foi puxado, e a `p3` do `sw2` foi lida a cada seis segundos:

```
root@sw2:~# bridge link show
461: p1@if462: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
464: p3@if463: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 2 
469: p10@if470: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw2:~# for i in 1 2 3 4 5 6 7; do date +%T; bridge link show dev p3 | grep -o "state [a-z]*"; sleep 6; done
09:10:11
state listening
09:10:18
state listening
09:10:24
state listening
09:10:30
state learning
09:10:36
state learning
09:10:43
state forwarding
09:10:49
state forwarding
```

A porta bloqueada é a que assume. Ela foi para `listening`, depois para `learning` em algum momento
entre 09:10:24 e 09:10:30, depois para `forwarding` em algum momento entre 09:10:36 e 09:10:43. As
amostras estão a seis segundos uma da outra, então essa é a precisão com que esta captura consegue
situar cada mudança. Enquanto isso, no `pc2`, o ping esteve rodando o tempo todo, e imprimiu o resumo
quando terminou:

```
ana@pc2:~$ ping -c 60 -i 1 -q 10.20.10.21
PING 10.20.10.21 (10.20.10.21) 56(84) bytes of data.

--- 10.20.10.21 ping statistics ---
60 packets transmitted, 30 received, 50% packet loss, time 60088ms
rtt min/avg/max/mdev = 0.441/1.246/11.610/2.076 ms
```

**60 enviados, 30 respondidos: meio minuto sem caminho entre dois PCs, numa rede com um cabo
reserva em perfeito estado.** São dois forward delays, 15 segundos de listening e 15 de learning,
durante os quais a porta não encaminhou nada.

## Os três temporizadores

| temporizador | padrão | o que ele decide |
| --- | --- | --- |
| hello time | 2 s | com que frequência os BPDUs da raiz são enviados |
| max age | 20 s | quanto tempo um switch guarda o último BPDU que ouviu antes de concluir que o caminho por trás dele sumiu |
| forward delay | 15 s | quanto tempo uma porta passa em listening, e de novo em learning |

O `sw2` não esperou o max age, porque o cabo morto estava na própria porta raiz dele e ele viu o
sinal sumir. **Quando a falha é em outro lugar, um switch só fica sabendo porque os BPDUs param de
chegar**, e antes espera o max age: 20 segundos, e depois mais 30 de listening e learning, uns 50
segundos ao todo. Para uma ligação telefônica ou uma conexão de banco de dados, os dois números são
uma interrupção, e são o motivo da próxima seção.
