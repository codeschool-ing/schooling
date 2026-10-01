---
title: Uma máscara errada, e o que ela quebra
version: 1
---

**Toda vez que uma máquina manda um pacote, ela usa a própria
máscara para decidir uma coisa.** O destino está no meu enlace, então peço o MAC dele e mando direto? Ou
está em outro lugar, então entrego o pacote ao gateway? Uma máscara errada erra essa decisão para
alguns destinos e acerta para outros, e é por isso que a falha que ela causa confunde tanto.

O sales1 como foi montado, com o seu `/25`:

```
ana@sales1:~$ ip route
default via 10.20.32.1 dev eth0 
10.20.32.0/25 dev eth0 proto kernel scope link src 10.20.32.10 
ana@sales1:~$ ip route get 10.20.32.100
10.20.32.100 dev eth0 src 10.20.32.10 uid 1000 
    cache 
ana@sales1:~$ ip route get 10.20.32.140
10.20.32.140 via 10.20.32.1 dev eth0 src 10.20.32.10 uid 1000 
    cache 
```

Duas rotas. `10.20.32.0/25 dev eth0` é a **rota conectada**, que o Linux acrescenta sozinho a partir do
endereço e da máscara: tudo de `.0` a `.127` está na `eth0`, alcançado direto. `default via 10.20.32.1` é
todo o resto. O `ip route get` mostra a decisão para dois destinos. `.100` está dentro do `/25`, então a
resposta é `dev eth0` sem `via`: o sales1 pediria ele mesmo o MAC de `.100`, embora nenhuma máquina deste
laboratório tenha esse endereço. `.140` está fora, então a resposta é `via 10.20.32.1`: o pacote vai para
o r1, que sabe que o eng1 está na sua `eth2`.

Agora o erro, digitado à mão: o endereço configurado de novo com `/24`, o tamanho do bloco inteiro, como
faria alguém que lembra que "o escritório é 10.20.32.0/24" e não lembra do plano.

```
root@sales1:~# ip addr del 10.20.32.10/25 dev eth0 && ip addr add 10.20.32.10/24 dev eth0 && ip route add default via 10.20.32.1
ana@sales1:~$ ip route
default via 10.20.32.1 dev eth0 
10.20.32.0/24 dev eth0 proto kernel scope link src 10.20.32.10 
ana@sales1:~$ ping -c 2 -W 1 10.20.99.10
PING 10.20.99.10 (10.20.99.10) 56(84) bytes of data.
64 bytes from 10.20.99.10: icmp_seq=1 ttl=62 time=11.4 ms
64 bytes from 10.20.99.10: icmp_seq=2 ttl=62 time=0.877 ms

--- 10.20.99.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.877/6.117/11.358/5.240 ms
ana@sales1:~$ ping -c 2 -W 1 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.

--- 10.20.32.140 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1056ms

```

A rota conectada agora é `10.20.32.0/24`. Um ping para o hq1, `10.20.99.10`, atrás do r2, funciona
perfeitamente, `ttl=62` porque atravessou dois roteadores. Um ping para o eng1, `10.20.32.140`, a dois
cabos de distância, perde os dois pacotes. **A máquina longe funciona e a perto não**, o contrário do
que qualquer um espera de uma falha de rede. A tabela de vizinhos diz por quê:

```
ana@sales1:~$ ip neigh
10.20.32.1 dev eth0 lladdr 02:a6:80:20:13:54 REACHABLE 
10.20.32.140 dev eth0 INCOMPLETE 
ana@sales1:~$ ip route get 10.20.32.140
10.20.32.140 dev eth0 src 10.20.32.10 uid 1000 
    cache 
```

`10.20.32.140 dev eth0 INCOMPLETE`. O sales1 achou que o eng1 estava no seu próprio enlace, porque `.140`
está dentro do `/24` que ele agora tem, então mandou pedidos ARP por `.140` pela `eth0` e esperou
resposta. O eng1 está em outro cabo, atrás do r1, e nunca os ouviu. O r1 os ouviu na `eth1` e também não
respondeu, porque `.140` não é um endereço dele. O `ip route get` confirma: `dev eth0`, sem `via`. O pacote
nem chegou a ir para o gateway.

**O sintoma de uma máscara curta demais é um conjunto de endereços que falham juntos e uma entrada
`INCOMPLETE` para cada um que se tentou.** Aqui o conjunto é de `.128` a `.255`, a LAN do eng1 e a do ops1,
porque esses são os endereços que o `/24` errado acrescentou à ideia que o sales1 tem do próprio enlace.
A internet, a matriz e o próprio gateway continuam funcionando, então o chamado do usuário vai dizer
"alguns servidores caíram", e os servidores estão bem.

O erro oposto, uma máscara longa demais, não foi executado neste laboratório. Ele faz uma máquina mandar
para o gateway os pacotes dos seus vizinhos de verdade; se eles chegam depois disso depende do que o
roteador faz com um pacote que precisa voltar pela mesma interface por onde entrou.

Diagnosticar qualquer um dos dois leva dois comandos, ambos vistos nesta aula. **Compare o endereço e o
prefixo do `ip -br addr` com o plano, e pergunte ao `ip route get` pelo endereço que falha.** Um destino
que deveria ser remoto respondendo `dev eth0` sem `via` é uma máscara curta demais, e uma linha
`INCOMPLETE` no `ip neigh` é o mesmo fato visto do outro lado.
