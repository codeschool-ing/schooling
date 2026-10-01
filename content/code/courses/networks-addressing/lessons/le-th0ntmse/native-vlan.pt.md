---
title: A VLAN nativa, e os erros que ela esconde
version: 1
---

Primeiro, o experimento para o qual o pc5 foi montado. O endereço dele, 10.20.10.25/24, está na
sub-rede do pc1, e a porta dele no sw2 está na VLAN 20. O pc1 o pinga, olha a tabela de vizinhos e o
pinga mais uma vez enquanto o pc5 escuta ARP:

```
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1026ms

ana@pc1:~$ ip neigh
10.20.10.25 dev eth0 INCOMPLETE 
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

root@pc5:~# timeout 6 tcpdump -n -e -i eth0 arp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

Nada passa, e a tabela de vizinhos diz por quê: `INCOMPLETE` quer dizer que o pc1 perguntou quem tem
10.20.10.25 e ninguém respondeu. A captura do pc5 tem `0 packets captured`, então a pergunta nunca
chegou a ele. O broadcast do pc1 foi posto na VLAN 10 no sw1, cruzou o tronco com tag da VLAN 10, e
o sw2 o entregou à sua porta da VLAN 10, que é a do pc3. **O endereço diz em que sub-rede uma
máquina acredita estar; a porta do switch decide em que domínio de broadcast ela de fato está, e
quando os dois discordam a porta vence.** Uma porta no lugar errado parece exatamente isto vista do
PC: um endereço correto, o link aceso e silêncio.

## A única VLAN que um tronco leva sem tag

Um tronco põe tag nos quadros, com uma exceção. A VLAN cujos quadros o cruzam sem tag se chama
**VLAN nativa** (termo da Cisco; o padrão fala do PVID da porta). Um quadro que chega num tronco sem
tag vai para a VLAN nativa da porta que o recebe, então **as duas pontas de um tronco têm de
concordar sobre qual VLAN é essa**, e nada no quadro pode dizer a elas se concordam.

Para ver o que a discordância faz, o laboratório dá à p24 do sw1 a VLAN 10 como VLAN sem tag, e à
p24 do sw2 a VLAN 20:

```
root@sw1:~# bridge vlan add dev p24 vid 10 pvid untagged
root@sw2:~# bridge vlan add dev p24 vid 20 pvid untagged
root@sw1:~# bridge vlan show dev p24
port              vlan-id  
p24               1 Egress Untagged
                  10 PVID Egress Untagged
                  20
root@sw2:~# bridge vlan show dev p24
port              vlan-id  
p24               1 Egress Untagged
                  10
                  20 PVID Egress Untagged
```

No sw1, a VLAN 10 agora é `PVID Egress Untagged` no tronco; no sw2 é a VLAN 20. (A VLAN 1 perdeu o
`PVID` nos dois e continua listada como saindo sem tag, uma sobra que a correção abaixo também não
limpa.) Então o pc1 pinga o pc5, que ele não alcançava no teste acima, e o pc3, que alcançava:

```
ana@pc1:~$ ping -c 2 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.934/1.096/1.258/0.162 ms
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1034ms

```

O pc1 alcança o pc5, na VLAN 20, e perde o pc3, na própria VLAN 10. Siga o quadro mais uma vez. Ele
entra no sw1 na VLAN 10; a VLAN 10 está sem tag na p24, então ele sai sem tag; o sw2 recebe um quadro
sem tag na p24 e o põe na sua VLAN sem tag, a 20, onde vive o pc5. A resposta faz o mesmo caminho ao
contrário. **Um descompasso de VLAN nativa solda duas VLANs através de um cabo**, e a VLAN que devia
estar nas duas pontas apaga. A bridge do Linux no laboratório não disse nada. Alguns switches
percebem — o protocolo de descoberta da Cisco, o CDP, registra um descompasso de VLAN nativa no log
— e uma linha de log só serve para quem a lê.

A mesma propriedade é o motivo de a VLAN nativa aparecer em todo guia de endurecimento de switch.
**O tráfego sem tag num tronco cai em qualquer VLAN que a ponta receptora disser**, então um tronco
cuja VLAN nativa também é uma VLAN com usuários dá aos quadros sem tag um caminho que nenhum tag
decidiu. Os ataques conhecidos contra a separação de VLANs, reunidos sob o nome VLAN hopping, se
apoiam exatamente nisso e em portas que aceitam virar tronco quando alguém pede. Este curso não os
ensina; ensina a configuração que os deixa sem ter com o que trabalhar.

## A correção, e a configuração que devia ter existido

As duas pontas recebem a mesma VLAN nativa, e é um número que ninguém usa, 999. As VLANs 10 e 20
voltam a ter tag:

```
root@sw1:~# bridge vlan add dev p24 vid 10 && bridge vlan add dev p24 vid 999 pvid untagged
root@sw2:~# bridge vlan add dev p24 vid 20 && bridge vlan add dev p24 vid 999 pvid untagged
root@sw1:~# bridge vlan show dev p24
port              vlan-id  
p24               1 Egress Untagged
                  10
                  20
                  999 PVID Egress Untagged
```

```
ana@pc1:~$ ping -c 2 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 1.050/4.222/7.394/3.172 ms
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.25
PING 10.20.10.25 (10.20.10.25) 56(84) bytes of data.

--- 10.20.10.25 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1035ms

```

O pc3 responde de novo e o pc5 fica inalcançável de novo, que é o resultado correto: o pc5 está na
VLAN errada, e agora a rede diz isso. Nenhuma porta do laboratório é de acesso na VLAN 999, então
**um quadro sem tag que chega ao tronco agora cai numa VLAN onde ninguém está escutando**.

As defesas cabem num parágrafo, e nenhuma custa nada para aplicar. Faça da VLAN nativa um número sem
uso, o mesmo nas duas pontas, sem porta de usuário nela. Liste as VLANs que cada tronco leva e deixe
o resto de fora. Fixe toda porta voltada para um usuário como porta de acesso e desligue a negociação
automática de tronco onde o switch a tiver (a da Cisco se chama DTP). Mantenha usuários fora da VLAN
1, com que todo switch começa e para onde todo erro de configuração volta, e desligue as portas sem
nada ligado. Onde o switch permitir, ponha tag também na VLAN nativa, para que nada num tronco viaje
sem tag. A p24 do laboratório ainda lista a VLAN 1 como sem tag; uma configuração mais caprichada a
removeria com `bridge vlan del`, que não foi executado aqui.
