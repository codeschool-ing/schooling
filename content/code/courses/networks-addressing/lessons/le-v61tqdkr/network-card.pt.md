---
title: "A placa de rede: onde o cabo encontra o computador"
version: 2
---

Todo equipamento da aula 1 tem placas de rede, e todo computador que conversa com eles também.
**Uma placa de rede transforma quadros num sinal no meio físico e o sinal de volta em quadros, e
carrega o endereço MAC que dá nome ao equipamento no seu enlace.** É a única peça que pertence às
camadas 1 e 2 ao mesmo tempo: ela produz o sinal, e decide quais quadros são da sua máquina.

A imagem comum é uma placa encaixada num slot. Isso ainda existe, mas hoje a maioria das placas é
um chip na placa-mãe, um rádio dentro de um laptop, ou, como neste laboratório, hardware nenhum.
Para o sistema operacional todas parecem iguais: uma interface com nome, endereço e contadores. Esta
aula roda no escritório da aula 1, montado de novo com `sudo bash ~/netlab/netlab.sh up office`.
Esta é a do pc1:

```
ana@pc1:~$ ip link show eth0
78: eth0@if77: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
ana@pc1:~$ ethtool -i eth0
driver: veth
version: 1.0
firmware-version: 
expansion-rom-version: 
bus-info: 
supports-statistics: yes
supports-test: no
supports-eeprom-access: no
supports-register-dump: no
supports-priv-flags: no
```

`ip link show` mostra a interface `eth0`, os flags de estado, e na segunda linha o endereço MAC,
**`02:25:70:bc:29:c6`**. `LOWER_UP` é a placa avisando que há um enlace vivo do outro lado.
`link-netns sw1` é o laboratório aparecendo: a outra ponta deste cabo está dentro do namespace
chamado sw1, o switch.

`ethtool -i` pergunta à placa sobre ela mesma, e a resposta é a honesta: **`driver: veth`, um par
Ethernet virtual**, que é a placa e o cabo do laboratório num único software. Numa máquina física,
essa linha traz o driver do chip de verdade, e os campos vazios `firmware-version` e `bus-info`
trariam o firmware da placa e o slot dela na placa-mãe. Uma placa virtual não tem nenhum dos dois.

## Os contadores

Uma placa conta o que faz, e esses contadores são o primeiro lugar para olhar quando um enlace se
comporta mal. Aqui estão eles antes e depois de cinco pings ao servidor:

```
ana@pc1:~$ ip -s link show eth0
78: eth0@if77: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
    RX:  bytes packets errors dropped  missed   mcast           
          1788      22      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
           570       7      0       0       0       0 
ana@pc1:~$ ping -c 5 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4011ms
rtt min/avg/max/mdev = 0.592/2.146/6.059/1.984 ms
ana@pc1:~$ ip -s link show eth0
78: eth0@if77: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
    RX:  bytes packets errors dropped  missed   mcast           
          2390      29      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          1102      13      0       0       0       0 
```

Leia a coluna `packets` de cada par de linhas:

| | antes | depois | diferença |
|---|---|---|---|
| recebidos (RX) | 22 | 29 | 7 |
| enviados (TX) | 7 | 13 | 6 |

Cinco pedidos de eco saíram e cinco respostas voltaram, então cinco de cada diferença são o ping.
O resto são quadros que não são pings: o laboratório tinha esvaziado todas as tabelas de vizinhos
antes deste bloco, então o pc1 precisou perguntar com ARP o MAC do servidor antes de o primeiro ping
sair. **Um contador conta quadros, seja o que for que levem dentro**, e é por isso que ele nunca
bate exatamente com o número de pings.

As colunas que importam num enlace de verdade são as que ficaram em zero aqui. `errors` conta
quadros que chegaram danificados, `dropped` conta quadros para os quais o sistema não tinha espaço,
e `collsns` conta colisões, que a aula 18 explica e que um enlace full duplex moderno nunca tem.
**`errors` que continuam subindo apontam para a camada 1**: um cabo danificado, um conector de
fibra sujo, uma porta com defeito. Leia duas vezes, com um minuto de intervalo. Um número que não
se mexeu é história; um número que está se mexendo é a falha.
