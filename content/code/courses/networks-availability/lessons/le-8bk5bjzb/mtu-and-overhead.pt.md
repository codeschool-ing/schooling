---
title: O MTU que um túnel tira
version: 1
---

Um enlace Ethernet leva pacotes IP de até **1500 bytes**, o MTU dele. O pacote de um túnel também
precisa caber nisso, cabeçalho incluído, então o pacote de dentro pode ter no máximo 1500 menos o custo
do túnel: **1480 no IP-in-IP, 1472 no GRE com chave**. É por isso que os túneis desta aula receberam
esses MTUs.

Um pacote grande demais para o próximo enlace é fragmentado, dividido em pedaços, a menos que quem o
enviou tenha ligado o bit **Don't Fragment**, o que quase toda conexão TCP faz. Aí o roteador o descarta
e devolve uma mensagem ICMP dizendo de que tamanho ele pode ser. `ping -M do` liga o bit, e `-s` define o
tamanho dos dados, aos quais o ping soma 8 bytes de ICMP e 20 de IP. Pelo túnel IP-in-IP:

```
ana@laptop:~$ ping -c 1 -M do -s 1472 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 1472(1500) bytes of data.
From 192.168.10.1 icmp_seq=1 Frag needed and DF set (mtu = 1480)

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

ana@laptop:~$ ping -c 1 -M do -s 1452 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 1452(1480) bytes of data.
1460 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=0.606 ms

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.606/0.606/0.606/0.000 ms
```

O pacote de 1500 bytes foi recusado por `hq`, `192.168.10.1`, com **`Frag needed and DF set (mtu =
1480)`**. O de 1480 passou. O laptop não só imprimiu a mensagem, ele guardou a informação:

```
ana@laptop:~$ ip route get 192.168.20.30
192.168.20.30 via 192.168.10.1 dev eth0 src 192.168.10.20 uid 1001 
    cache expires 599sec mtu 1480 
```

Pelos próximos dez minutos, `599sec`, todo pacote que o laptop mandar para o caixa sai do tamanho de
1480. Isso é a **descoberta do MTU do caminho** (path MTU discovery), e funciona sem ninguém configurar
nada, com uma condição: a mensagem ICMP precisa chegar a quem enviou.

Um firewall que descarta todo ICMP "por segurança" quebra justamente isso. O pacote grande é descartado,
a mensagem que diria por quê também, e quem envia continua tentando um tamanho que nunca vai passar.
Coisas pequenas funcionam, as primeiras linhas de uma página ou uma tela de login, e qualquer coisa
grande trava sem erro. Isso se chama **buraco negro de PMTU**, e a aula 21 encontra um passo a passo. A
correção lá é a usada em quase todo roteador de VPN: reescrever o tamanho máximo de segmento que o TCP
anuncia, para que as conexões nunca tentem mandar pacotes que não cabem.

O custo também aparece na vazão, menor do que se teme. Vinte e oito bytes num pacote de 1500 é menos de
2%. Num fluxo de pacotes pequenos, voz por exemplo, em que cada pacote leva 160 bytes de áudio, os mesmos
28 bytes pesam muito mais no total, e um planejamento de banda que os esquece fica curto.

As duas interfaces mostram a conta lado a lado:

```
ana@hq:~$ ip link show tun0; ip link show eth1
3: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1472 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 500
    link/none 
893: eth1@if894: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:00:71:02 brd ff:ff:ff:ff:ff:ff link-netnsid 1
```

`eth1`, o enlace para o provedor, leva 1500. `tun0`, o túnel GRE por cima dele, leva 1472, e `link/none`
diz que ele não tem endereço de hardware nenhum.
