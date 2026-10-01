---
title: "Domínios de broadcast: até onde vai uma pergunta"
version: 1
---

Alguns quadros são para todos. A pergunta do ARP, *quem tem 10.20.10.22?*, precisa chegar a uma
máquina cujo endereço MAC o remetente ainda não sabe, então ela vai para o endereço de broadcast,
`ff:ff:ff:ff:ff:ff`, e todo switch a inunda. **Um domínio de broadcast é o conjunto de equipamentos
que um broadcast alcança**, e o útil a saber sobre ele é onde termina.

Uma crença comum é que um switch separa broadcasts, já que separa todo o resto. Não separa: um
switch divide domínios de colisão, e passa broadcasts por todas as portas, porque um broadcast pede
para ser entregue em todo lugar. Neste bloco o pc1, com a tabela de vizinhos esvaziada, pinga o
pc2, enquanto o pc3 escuta ARP. O tcpdump do pc3 foi iniciado antes e imprimiu quando parou:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 3.034/3.034/3.034/0.000 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:58:31.168784 02:25:70:bc:29:c6 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 10.20.10.22 tell 10.20.10.21, length 28

1 packet captured
1 packet received by filter
0 packets dropped by kernel
```

O pc3 pegou **um quadro, do MAC do pc1 para `ff:ff:ff:ff:ff:ff`: `Request who-has 10.20.10.22 tell
10.20.10.21`**. Não cabe ao pc3 responder, e o pc3 não respondeu, mas a placa dele recebeu o quadro
e o sistema teve de olhá-lo. Toda máquina do sw1, inclusive a interface do roteador no escritório,
recebeu o mesmo quadro.

A segunda metade do bloco escuta do outro lado do roteador. A máquina do provedor, o isp, fica na
outra interface do r1. A tabela de vizinhos do pc1 é esvaziada de novo e o mesmo ping é repetido,
então a mesma pergunta em broadcast sai outra vez:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 1.244/1.244/1.244/0.000 ms
root@isp:~# timeout 6 tcpdump -n -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

**O isp não capturou nada.** A pergunta chegou à interface do r1 no escritório, como chegou a todos
do sw1, e parou ali. **Um roteador não encaminha broadcasts**: ele encaminha pacotes endereçados a
outra rede, e um quadro para todos deste enlace não é endereçado a outra rede alguma. Então cada
interface de um roteador é a borda de um domínio de broadcast, e o tráfego ARP do escritório nunca
chega ao provedor.

## Contando

Ponha as aulas 1 e 2 e esta lado a lado:

| equipamento | domínios de colisão | domínios de broadcast |
|---|---|---|
| hub ou repetidor | um, dividido por todas as portas | um |
| bridge ou switch | um por porta | um, dividido por todas as portas |
| roteador | um por interface | um por interface |

Neste laboratório, as cinco portas do sw1 são cinco domínios de colisão e um domínio de broadcast,
10.20.10.0/24; o enlace do r1 com o provedor é outro domínio de broadcast; e assim por diante, um
por rede.

## Por que o tamanho importa

**Cada broadcast é recebido e examinado por cada máquina do domínio.** Dez máquinas fazendo
perguntas ARP são ruído de fundo. Alguns milhares numa rede plana são uma carga constante em cada
uma delas, e um equipamento com defeito mandando broadcasts em laço é sentido em todo lugar ao mesmo
tempo. O pior caso é um cabo que liga duas portas da mesma rede comutada: um broadcast dá voltas no
laço para sempre, cada switch inunda cada cópia, e a rede para. Isso é uma **tempestade de
broadcast** (*broadcast storm*), e evitá-la é a aula 20.

Por isso as redes são cortadas em domínios de broadcast de propósito, um por departamento, andar ou
finalidade, com um roteador entre eles. Fazer isso com um switch separado para cada domínio é caro
e rígido; **a aula 19 corta um switch em vários domínios de broadcast** com VLANs, e a aula 22 põe o
roteador de volta entre eles.
