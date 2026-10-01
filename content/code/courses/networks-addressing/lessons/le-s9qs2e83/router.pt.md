---
title: "O roteador: entre redes"
version: 1
---

Um switch junta máquinas de uma rede. **Um roteador junta redes: ele tem um endereço em cada uma,
lê o endereço IP de destino de cada pacote, e manda o pacote adiante na direção da rede a que esse
endereço pertence.** O quadro em volta do pacote é jogado fora no roteador, e um novo é montado
para o próximo enlace, o que a aula 2 mostra byte a byte.

O roteador do laboratório é o r1. Ele tem duas interfaces, uma no escritório e outra na direção do
provedor:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0@if31        UP             10.20.10.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth1@if33        UP             203.0.113.2/30 fe80::a6:80ff:fe20:1354/64 
root@r1:~# ip route
default via 203.0.113.1 dev eth1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
203.0.113.0/30 dev eth1 proto kernel scope link src 203.0.113.2 
root@r1:~# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 1
```

`ip -br addr` dá ao r1 dois endereços em duas redes diferentes: `10.20.10.1/24` em `eth0`, o
escritório, e `203.0.113.2/30` em `eth1`, o enlace com o provedor. (Os endereços `fe80::` são
endereços IPv6 link-local, que toda interface ganha sozinha; a aula 9 trata deles.) `ip route` é a
**tabela de rotas**, com três linhas: as duas redes em que ele está cabeado, e `default via
203.0.113.1`, que diz que um pacote para qualquer outra rede vai para o provedor. A aula 14 lê
tabelas como esta linha por linha.

O terceiro comando é o que faz de uma máquina Linux um roteador. **`net.ipv4.ip_forward = 1` manda
o kernel passar pacotes de uma interface para outra**; com 0, a mesma máquina com as mesmas duas
placas é um host que por acaso está em duas redes e se recusa a carregar o tráfego dos outros.

Agora o pc1 pinga uma máquina da sua rede e uma do outro lado do roteador:

```
ana@pc1:~$ ping -c 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.
64 bytes from 10.20.10.10: icmp_seq=1 ttl=64 time=1.74 ms

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.738/1.738/1.738/0.000 ms
ana@pc1:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=62 time=7.49 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 7.487/7.487/7.487/0.000 ms
ana@pc1:~$ traceroute -n 192.0.2.80
traceroute to 192.0.2.80 (192.0.2.80), 30 hops max, 60 byte packets
 1  10.20.10.1  2.879 ms  0.590 ms  0.248 ms
 2  203.0.113.1  1.140 ms  0.774 ms  0.723 ms
 3  192.0.2.80  1.474 ms  0.824 ms  0.695 ms
```

Compare os dois valores de `ttl`. Todo pacote IP leva um **tempo de vida** (*time to live*), um
contador do qual cada roteador subtrai um antes de passar o pacote adiante; um pacote cujo contador
chega a zero é descartado, e é isso que impede um pacote de circular para sempre. O servidor em
10.20.10.10 respondeu com `ttl=64`, o valor em que o Linux começa, porque nenhum roteador estava
entre ele e o pc1. A resposta de 192.0.2.80 chegou com **`ttl=62`: dois roteadores a trataram na
volta**, o r1 e o provedor.

O `traceroute` dá o nome deles. Ele envia pacotes com tempo de vida 1, depois 2, depois 3, e cada
roteador que descarta um deles avisa. O primeiro salto é **10.20.10.1**, o endereço do r1 no
escritório; o segundo é **203.0.113.1**, o provedor; o terceiro é o próprio destino. Três saltos,
dois deles roteadores, a mesma conta que o `ttl` deu.

A ida e volta até 192.0.2.80 levou 7.49 ms contra 1.74 ms dentro do escritório, mas os cabos deste
laboratório não têm atraso algum, e os dois números medem um computador virtual fazendo todo o
trabalho. O que a captura mostra com segurança é a quantidade de roteadores, não o tempo.

Três coisas que um roteador faz e o equipamento da seção do switch não faz:

- **Ele separa redes.** Um broadcast, como a pergunta do ARP, para no roteador; a aula 18 assiste
  a um deles não conseguir atravessar o r1.
- **Ele descarta o que não tem rota**, em vez de inundar. Um switch que não conhece um destino
  manda o quadro para todo lado; um roteador sem linha correspondente e sem rota padrão descarta o
  pacote e avisa o remetente.
- **É nele que fica a política.** Como todo pacote entre o escritório e a internet atravessa o r1,
  é no r1 que ficam as regras da seção do firewall, e é ali que o NAT dá aos endereços privados do
  escritório um endereço público, o que é a aula 11.
