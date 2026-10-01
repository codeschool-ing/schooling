---
title: Broadcast, um pacote para todo mundo
version: 1
---

Um endereço de **broadcast** entrega um pacote a todas as máquinas de uma rede de uma vez. O IPv4 tem
dois tipos. O **broadcast dirigido** de uma rede é o seu último endereço, aquele com todos os bits de
host em 1: para `10.20.10.0/24` é `10.20.10.255`, a linha `Broadcast` que o ipcalc imprimiu na
primeira seção desta aula. O **broadcast limitado**, `255.255.255.255`, quer dizer todas as máquinas
deste enlace, seja qual for a rede, e é o que uma máquina ainda sem endereço usa para pedir um; a
aula 10 mostra um cliente DHCP fazendo isso.

O pc1 só precisa do próprio endereço e da máscara para deduzir o broadcast dirigido: a parte de host
são os últimos oito bits, e oito uns dão 255.

```
ana@pc1:~$ ip addr show eth0 | grep "inet "
    inet 10.20.10.21/24 scope global eth0
ana@pc1:~$ ping -b -c 2 10.20.10.255
WARNING: pinging broadcast address
PING 10.20.10.255 (10.20.10.255) 56(84) bytes of data.

--- 10.20.10.255 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1022ms

```

O `ping -b` é obrigatório porque o ping recusa um endereço de broadcast sem ele, e a linha `WARNING` é
o ping conferindo que era isso mesmo. Dois pedidos saíram e **nada voltou, 100% de perda**. A
conclusão errada é que o pedido não chegou a ninguém. Ele chegou a todas as máquinas do switch; cada
uma decidiu não responder. O Linux ignora um echo request mandado a um endereço de broadcast, a não
ser que alguém mande o contrário, e o pc2 diz isso:

```
ana@pc2:~$ sysctl net.ipv4.icmp_echo_ignore_broadcasts
net.ipv4.icmp_echo_ignore_broadcasts = 1
root@pc2:~# sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
net.ipv4.icmp_echo_ignore_broadcasts = 0
root@pc3:~# sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
net.ipv4.icmp_echo_ignore_broadcasts = 0
```

`icmp_echo_ignore_broadcasts = 1` é o padrão. O root do pc2 e do pc3 desligou a opção, a única
configuração deste escritório mudada em relação ao padrão, e só para esta demonstração. O mesmo
ping de novo:

```
ana@pc1:~$ ping -b -c 2 10.20.10.255
WARNING: pinging broadcast address
PING 10.20.10.255 (10.20.10.255) 56(84) bytes of data.
64 bytes from 10.20.10.23: icmp_seq=1 ttl=64 time=5.82 ms
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=5.84 ms
64 bytes from 10.20.10.23: icmp_seq=2 ttl=64 time=1.65 ms

--- 10.20.10.255 ping statistics ---
2 packets transmitted, 2 received, +1 duplicates, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.646/4.435/5.837/1.972 ms
```

Agora o pc3 (`.23`) e o pc2 (`.22`) responderam ao primeiro pedido. O ping conta uma resposta por
pedido como recebida e **cada resposta a mais ao mesmo pedido como duplicata**, então três respostas
a dois pedidos aparecem como `2 received, +1 duplicates`. O pc2 não respondeu ao segundo pedido nesta
execução, e a captura não mostra por quê. O srv e o r1 mantiveram o padrão e ficaram calados, como da
primeira vez.

Por que ignorar pings de broadcast é o padrão? Porque **um broadcast dirigido já deixou um pacote
virar centenas**. No fim dos anos 1990, um atacante podia mandar echo requests para o endereço de
broadcast da rede de outra pessoa, com um endereço de origem falsificado: o da vítima. Cada máquina
daquela rede respondia à vítima, e uma rede grande multiplicava cada pacote muitas vezes. Isso se
chamava ataque smurf, e dois padrões acabaram com ele. **Os roteadores deixaram de encaminhar
broadcasts dirigidos que chegam de fora** (a RFC 2644, de 1999, tornou isso o padrão obrigatório), e
os sistemas operacionais deixaram de responder a pings de broadcast, que é a opção acima. Os dois
continuam sendo o padrão, e uma rede em que algum deles foi mudado merece uma pergunta.

Um broadcast também para no roteador, sejam quais forem as opções. O broadcast do pc1 chegou ao pc2,
ao pc3, ao srv e à `eth0` do r1, e não foi além: **o conjunto de máquinas que um broadcast alcança é um
domínio de broadcast**, e neste escritório é tudo o que está ligado ao sw1. A aula 18 mede um, e a aula
19 divide um switch em vários com VLANs.

Broadcasts não são curiosidade. O ARP faz a sua pergunta por broadcast, como o curso de redes mostrou
no fio, e o DHCP começa com um. Toda máquina do domínio recebe cada um deles e gasta um pouco de
esforço decidindo ignorá-lo, e esse é um dos motivos para uma rede de milhares de máquinas ser
cortada em redes menores, em vez de montada como uma LAN plana só.
