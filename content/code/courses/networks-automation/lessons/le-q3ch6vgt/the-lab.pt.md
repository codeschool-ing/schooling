---
title: O laboratório em que este curso roda
version: 1
---

Todo comando deste curso foi executado, e toda linha de saída é o que o comando imprimiu. A rede
em que ele rodou é um laboratório: **nove máquinas construídas num só computador Linux**, cada uma
um namespace de rede com suas próprias interfaces, endereços e rotas, ligadas por cabos virtuais.

```
ana@ctl:~$ grep example.net /etc/hosts
192.0.2.10 ctl.example.net ctl
192.0.2.11 core1.example.net core1
192.0.2.12 edge1.example.net edge1
192.0.2.13 edge2.example.net edge2
192.0.2.21 nc1.example.net nc1
192.0.2.30 netbox.example.net netbox
192.0.2.40 tickets.example.net tickets
```

| máquina | o que é |
|---|---|
| `ctl` | o host de automação, onde você trabalha: Python, as bibliotecas, o Ansible e o Git |
| `core1`, `edge1`, `edge2` | roteadores: FRR para o roteamento e o CLI, SSH para esse CLI, uma API REST e uma porta gNMI |
| `nc1` | um equipamento gerido só pelo seu modelo de dados, por NETCONF e RESTCONF |
| `netbox` | o NetBox, a fonte da verdade da aula 12 |
| `tickets` | a central de chamados em que os webhooks da aula 7 abrem chamados |
| `pc1`, `pc2` | um computador na LAN de cada filial, para testar a rede a partir dele |

O `ctl` tem uma interface, na rede de gerência:

```
ana@ctl:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if36        UP             192.0.2.10/24 
ana@ctl:~$ python --version
Python 3.12.3
ana@ctl:~$ pip list 2>/dev/null | grep -iE "^(netmiko|napalm|nornir|ncclient|pygnmi|jinja2|pynetbox) "
Jinja2             3.1.6
napalm             5.2.0
ncclient           0.7.0
netmiko            4.8.0
nornir             3.6.0
pygnmi             0.8.15
pynetbox           7.8.0
```

**Os roteadores rodam o FRRouting**, a suíte de roteamento livre que também roda dentro de
vários produtos comerciais. O CLI dele é inspirado no da Cisco, e ele roteia de verdade: o OSPF
roda entre os três, e o `edge1` aprendeu a outra filial pelo `core1`:

```
ana@ctl:~$ ssh netops@edge1 "show version" | head -1
FRRouting 8.4.4 (edge1) on Linux(6.18.44-fc-v49).
ana@ctl:~$ ssh netops@edge1 "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
203.0.113.251     1 Full/-          25.256s           34.742s 198.51.100.1    eth1:198.51.100.2                    0     0     0

ana@ctl:~$ ssh netops@edge1 "show ip route ospf"
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   192.0.2.0/24 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:14
O   198.51.100.0/30 [110/10] is directly connected, eth1, weight 1, 00:00:35
O>* 198.51.100.4/30 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:15
O   203.0.113.0/26 [110/10] is directly connected, eth2, weight 1, 00:00:35
O>* 203.0.113.64/26 [110/30] via 198.51.100.1, eth1, weight 1, 00:00:15
O>* 203.0.113.251/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:14
O>* 203.0.113.253/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:14
```

**O que é real e o que foi escrito para o curso.** Os sistemas operacionais de rede que as
pessoas automatizam no trabalho são licenciados, então nenhuma imagem de fabricante roda aqui.
Tudo o que as aulas importam ou com que conversam é software livre de verdade (FRR, OpenSSH, o
Clixon do `nc1`, NetBox, Ansible e todas as bibliotecas Python mostradas acima), com três
exceções, escritas para o laboratório e nomeadas sempre que uma aula as usa. A API REST e a porta
gNMI dos roteadores são um pequeno programa que responde a partir do FRR e do kernel, porque o
FRR não tem nenhuma das duas. O driver NAPALM para FRR é outro, porque o NAPALM não traz um. A
central de chamados é o terceiro, porque os sistemas de chamados que as pessoas usam são grandes
demais para instalar por uma aula. Cada um segue o padrão que os produtos reais seguem, e as
aulas ensinam o padrão.

Os endereços são as faixas reservadas para documentação, `192.0.2.0/24`, `198.51.100.0/24` e
`203.0.113.0/24`, e os nomes terminam em `example.net`. **Nada no laboratório chega à internet.**

Para acompanhar em casa você precisa de uma máquina Linux, e uma máquina virtual é o caminho mais
fácil, com FRR e Python 3.12 instalados; um namespace por roteador é como este laboratório faz, e
uma máquina virtual por roteador funciona do mesmo jeito com mais memória. Onde seus roteadores
forem equipamentos de verdade, as bibliotecas são as mesmas e só o tipo de equipamento e os
endereços mudam.

**Quando algo não responde**, confira na ordem em que os pacotes viajam: o `ctl` alcança o
endereço, a porta está aberta, e o login é aceito à mão?

```
ana@ctl:~$ ping -c 1 edge1
PING edge1.example.net (192.0.2.12) 56(84) bytes of data.
64 bytes from edge1.example.net (192.0.2.12): icmp_seq=1 ttl=64 time=6.79 ms

--- edge1.example.net ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 6.791/6.791/6.791/0.000 ms
ana@ctl:~$ nc -vz edge1 22
Connection to edge1 (192.0.2.12) 22 port [tcp/ssh] succeeded!
```

O `ping` respondeu, e o `nc -vz` conectou na porta 22 sem enviar nada. A terceira pergunta é a
que a primeira seção fez, um `ssh netops@edge1` interativo. **Um script que falha em qualquer um
desses três lugares falha por um motivo que não está no script**, e nenhuma mudança no script
resolve.
