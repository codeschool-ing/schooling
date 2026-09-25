---
title: O que o ss diz sobre uma conexão
version: 1
---

Uma conexão tem um **estado** em cada ponta, e o `ss` mostra. Aqui o laptop mantém uma conexão SSH
aberta com o servidor web, e cada lado é consultado:

```
ana@laptop:~$ ss -tn
State Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
ESTAB 0      0      192.168.10.20:43624   192.0.2.80:22         
ana@www:~$ ss -tn
State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
ESTAB 0      0         192.0.2.80:22    203.0.113.2:43624       
ana@laptop:~$ ss -tan state time-wait
Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
0      0      192.168.10.20:60918   192.0.2.80:80         
0      0      192.168.10.20:43624   192.0.2.80:22         
```

`ESTAB`, estabelecida, nos dois, e as duas linhas descrevem a mesma conexão de cada ponta. O laptop se
vê como `192.168.10.20:43624`. **O servidor vê `203.0.113.2:43624`: o endereço público do escritório,
o NAT da aula 2**, com a mesma porta, porque o roteador não tinha motivo para mudá-la.

Quando a conexão foi fechada, ela não sumiu do laptop. `TIME-WAIT` é o estado em que fica o lado que
fechou primeiro, por 60 segundos no Linux, para que um pacote atrasado da conexão antiga não seja
confundido com parte de uma nova nas mesmas portas. A conexão web de antes também está lá, pelo mesmo
motivo. Um servidor mostrando milhares de linhas `TIME-WAIT` é um servidor ocupado, não quebrado.

Os estados que vale reconhecer:

| estado | quer dizer |
|---|---|
| `LISTEN` | um servidor esperando conexões |
| `SYN-SENT` | um cliente que mandou SYN e ainda não ouviu nada |
| `ESTAB` | aberta, os dados podem passar |
| `TIME-WAIT` | fechada aqui, esperando pacotes perdidos |
| `CLOSE-WAIT` | o outro lado fechou, e este programa não |

`SYN-SENT` que dura é uma conexão que ninguém responde: seção 07. `CLOSE-WAIT` que se acumula é um
programa que esquece de fechar as conexões, um defeito do programa e não da rede.
