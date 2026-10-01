---
title: Protegendo a árvore do que é conectado nela
version: 1
---

O spanning tree acredita em todo BPDU que recebe. É isso que o faz funcionar sem configuração, e é
também o seu lado fraco: **qualquer dispositivo que manda BPDUs participa da eleição**, seja o switch
de núcleo, seja um switch barato que alguém trouxe de casa e ligou embaixo da mesa.

Duas coisas podem dar errado. Se o dispositivo novo tiver um ID de ponte menor, ele **vira a raiz**,
e a rede inteira se reorganiza em torno dele: o tráfego entre dois andares pode passar a atravessar
um switch de mesa, por um cabo que ninguém planejou. E uma pessoa que liga duas tomadas de rede ao
mesmo switch pequeno, ou conecta as duas pontas de um cabo nele, monta o laço da primeira seção
desta lição num lugar que ninguém está olhando. As defesas abaixo são todas configurações nas portas
onde esses dispositivos aparecem: a borda.

## BPDU guard: uma porta que dá para um computador nunca deveria ouvir um BPDU

Uma porta com um PC, uma impressora ou um telefone não tem motivo para receber tráfego de spanning
tree, então receber qualquer um é sinal de que apareceu um switch ali. **O BPDU guard desliga a
porta no momento em que chega um BPDU.** Ele foi ligado na `p10` do `sw1`, a porta onde está o
`pc1`:

```
root@sw1:~# bridge link set dev p10 guard on
root@sw1:~# bridge link show dev p10
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@pc1:~# ip link add br9 type bridge stp_state 1 && ip link set eth0 master br9 && ip link set br9 up
root@sw1:~# bridge link show dev p10
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state disabled priority 32 cost 2 
```

O comando no `pc1` o faz se comportar como um switch pequeno rodando spanning tree: cria uma bridge
com STP ligado e põe a placa de rede dentro dela, então a placa começa a mandar BPDUs. Seis segundos
depois a `p10` do `sw1` estava em **`state disabled`**, embora o cabo continuasse conectado e o
enlace continuasse `LOWER_UP`. Uma porta protegida não discute a eleição; ela sai dela. O `pc1`
perdeu a rede, e essa é a ideia: quem ligou o switch percebe, e o resto da rede não.

A captura para aí. Como uma porta volta é decisão de quem administra o switch: na maioria dos
equipamentos alguém a reabilita à mão depois de achar o dispositivo, e alguns podem ser configurados
para tentar de novo sozinhos depois de um tempo.

## Root guard: a raiz nunca pode estar deste lado

O BPDU guard serve para portas que não deveriam ouvir BPDU nenhum. O **root guard** é para portas
que dão para outros switches de forma legítima, como os cabos de um switch de distribuição até os
switches de acesso. BPDUs ali são normais, mas um que anuncie uma raiz melhor que a atual não é. Uma
porta com root guard que recebe um BPDU desses para de encaminhar até esses BPDUs pararem, e a raiz
fica onde foi posta.

## BPDU filter, e por que ele é perigoso

O **BPDU filter** faz uma porta parar de mandar BPDUs e ignorar os que recebe. Ele às vezes é usado
em portas que dão para a rede de outra organização, onde as duas árvores não podem se fundir. Numa
porta de acesso comum ele é o contrário de proteção: **uma porta que ignora BPDUs não consegue
descobrir que faz parte de um laço**, então um cabo entre duas portas filtradas é a tempestade da
primeira seção com o spanning tree ligado em todo o resto. Se uma porta deve dar só para
computadores, o BPDU guard é a configuração que diz isso e age de acordo.

## A última linha: storm control

Tudo acima evita um laço. O **storm control** limita o estrago de um que aconteça mesmo assim: uma
porta recebe um teto para o tráfego de broadcast e multicast que aceita, e acima dele o excesso é
descartado ou a porta é desligada. Ele não encontra o laço. Ele impede que um laço derrube o segmento
inteiro, e dá a alguém o tempo de achar o cabo.
