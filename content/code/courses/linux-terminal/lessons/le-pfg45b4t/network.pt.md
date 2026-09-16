---
title: A rede, que é um dispositivo com fila
version: 1
---

Uma interface de rede é um dispositivo com fila, então as mesmas três perguntas
funcionam: quão ocupada, quanto está esperando, e quantos erros.

## O que está escutando, e para quem

```
ana@vm:~$ ss -s
Total: 29
TCP:   18 (estab 13, closed 1, orphaned 0, timewait 1)

Transport Total     IP        IPv6
RAW       0         0         0
UDP       0         0         0
TCP       17        17        0
INET      17        17        0
FRAG      0         0         0
```

O `ss -s` é o resumo de uma linha: quantos sockets, quantos estabelecidos,
quantos em `TIME-WAIT`.

```
ana@vm:~$ ss -tulpn 2>/dev/null | head -8
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
tcp   LISTEN 0      512        127.0.0.1:42989      0.0.0.0:*
tcp   LISTEN 0      4096       127.0.0.1:45939      0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:2024       0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:2025       0.0.0.0:*
```

**O `ss -tulpn` é o de decorar**, e as letras soletram o que ele faz:

| | |
|---|---|
| `-t` `-u` | TCP e UDP |
| `-l` | só sockets escutando |
| `-p` | qual processo — precisa de privilégio para ver os de outros usuários |
| `-n` | numérico. **Não resolva nomes**, que é o que o torna instantâneo |

O `0.0.0.0:2025` é alcançável pela rede; o `127.0.0.1:45939` não é. Essa
distinção é uma questão de segurança tanto quanto de desempenho, e o `ss -tulpn`
é como você responde "este serviço está mesmo exposto".

O `ss` substituiu o `netstat`, que está no pacote `net-tools` que a maioria das
distribuições já não instala. As traduções são diretas: o `netstat -tulpn` é o
`ss -tulpn`, o `netstat -s` é o `ss -s`, o `netstat -rn` é o `ip route`.

## As duas filas

As colunas `Recv-Q` e `Send-Q` querem dizer coisas diferentes conforme o estado,
que é a parte confusa.

**Num socket em `LISTEN`:**

| | |
|---|---|
| `Recv-Q` | conexões **aceitas pelo kernel e ainda não pegas** pelo programa |
| `Send-Q` | o tamanho do backlog — o máximo que a primeira coluna pode alcançar |

`Recv-Q` acima de zero num ouvinte quer dizer que a aplicação não está chamando
`accept()` rápido o bastante. `Recv-Q` igual ao `Send-Q` quer dizer que está
cheio, e conexões novas estão sendo descartadas. **Esse é o número mais útil
desta seção**: ele diz "o servidor está sobrecarregado" sem ambiguidade nenhuma.

**Num socket estabelecido**, eles são bytes: dados recebidos e ainda não lidos
pela aplicação, e dados escritos pela aplicação e ainda não confirmados pelo
outro lado. Um `Send-Q` grande que não drena é um par lento ou ausente.

## Erros e descartes

```
ana@vm:~$ ip -s link show eth0
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 02:fc:00:00:00:01 brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast
     365057734  262464      0       6       0       0
    TX:  bytes packets errors dropped carrier collsns
     426949616  260028      0       0       0       0
```

**Seis pacotes recebidos descartados em 262.464.** Esse é o `E` do método USE da
seção 02, e é o número que ninguém olha.

| | |
|---|---|
| `errors` | quadros malformados, falhas de checksum. Um cabo ou uma placa |
| `dropped` | o pacote estava bom e não havia onde pô-lo. Um **buffer** |
| `missed` | a placa não tinha descritor livre. O driver não deu conta |

Seis descartes em um quarto de milhão é ruído. A mesma proporção a um milhão de
pacotes por segundo são milhares por segundo, e aparece como lentidão ocasional e
irreprodutível numa aplicação que não faz ideia de que algo está errado.

O `cat /proc/net/dev` são os mesmos contadores, sem formatação, e é o que você
analisa num script.

## Detalhe por conexão

O `ss -ti` acrescenta a visão do próprio kernel de toda conexão estabelecida — a
janela de congestionamento, o tempo de ida e volta suavizado, retransmissões, a
taxa de ritmo. É uma linha muito larga por socket, larga demais para uma página
como esta, e vale rodar uma vez numa conexão de verdade para ver o que há lá.

Os dois campos a procurar nela são o **`rtt`** — quão longe o outro lado está de
fato — e o **`retrans`**, que conta retransmissões. Retransmissões numa rede local
querem dizer que algo está quebrado; na internet elas são comuns.

## Contadores, não taxas

Todo número desta seção exceto o `ss -s` é um **contador desde o boot**. Um número
grande não é problema e um número crescendo pode ser.

```sh
ip -s link show eth0 ; sleep 10 ; ip -s link show eth0     # subtract
sar -n DEV 1                                                # or let sysstat do it
sar -n EDEV 1                                               # the error counters, as rates
```

**O `sar -n DEV 1` é a ferramenta certa**, porque ele faz a subtração por você:

```
ana@vm:~$ sar -n DEV 1 1 2>&1 | grep -E 'IFACE|eth0'
11:39:28        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
11:39:29         eth0      2.00      3.00      0.13      0.19      0.00      0.00      0.00      0.00
```

Dois pacotes por segundo entrando, três saindo, e uma utilização de interface de
zero. Esses são números sobre os quais dá para agir; `RX packets 262464` não é. É
esse o assunto inteiro da próxima seção, e os contadores de rede são onde ele
morde mais forte — ninguém nunca olhou um total desde o boot e soube se era
muito.

E o `netstat` realmente sumiu numa máquina atual:

```
ana@vm:~$ which netstat || echo 'netstat: not installed'
netstat: not installed
```
