---
title: GRE, e o que quatro bytes a mais compram
version: 1
---

**O GRE, Generic Routing Encapsulation, coloca um cabeçalho pequeno próprio entre o cabeçalho IP externo
e a carga.** É o protocolo IP 47. O campo principal do cabeçalho diz o que vai dentro, então o GRE leva
coisas que o IP-in-IP não leva: IPv6, o multicast de um protocolo de roteamento como o OSPF, ou quadros
Ethernet. Essa flexibilidade é o motivo de a maioria dos enlaces site a site entre roteadores de
fabricantes diferentes ter sido GRE por duas décadas, muitas vezes com IPsec em volta, que é o assunto
da aula 2.

Num roteador Linux é um comando. No kernel em que estas transcrições foram gravadas, ele falha:

```
ana@hq:~$ sudo ip link add gre1 type gre local 203.0.113.2 remote 198.51.100.2 key 42
Error: Unknown device type.
```

`Unknown device type` quer dizer que aquele kernel não tem o módulo de GRE, não que o comando esteja
errado. No seu Ubuntu o mesmo comando não imprime nada e cria um túnel chamado `gre1`, que esta aula não
usa: apague-o com `sudo ip link del gre1`, para que o único túnel em `hq` seja o de baixo.

O curso roda o `tunnel.py` de novo, em modo GRE, com os mesmos endereços e chave 42. O túnel IP-in-IP sai
antes, nas duas pontas. Cada `tunnel.py` tem de ser parado na própria máquina, que é o que o
`netlab.sh kill` faz, digitado na máquina virtual; quando o programa termina, o `tun0` dele some e a rota
que passava por ele vai junto. Depois, o túnel novo, em `hq` e em `branch`:

```
ana@netlab:~$ sudo bash netlab.sh kill hq tunnel.py; sudo bash netlab.sh kill branch tunnel.py
ana@hq:~$ sudo setsid tunnel.py gre tun0 203.0.113.2 198.51.100.2 42 & sleep 1; sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.20.0/24 via 10.0.0.2
ana@branch:~$ sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@isp:~$ sudo tcpdump -n -t -v -i eth0 -c 2 ip proto 47
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP (tos 0x0, ttl 64, id 22377, offset 0, flags [DF], proto GRE (47), length 112)
    203.0.113.2 > 198.51.100.2: GREv0, Flags [key present], key=0x2a, length 92
	IP (tos 0x0, ttl 63, id 39025, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.10.20 > 192.168.20.30: ICMP echo request, id 31773, seq 1, length 64
IP (tos 0x0, ttl 63, id 11888, offset 0, flags [DF], proto GRE (47), length 112)
    198.51.100.2 > 203.0.113.2: GREv0, Flags [key present], key=0x2a, length 92
	IP (tos 0x0, ttl 63, id 41473, offset 0, flags [none], proto ICMP (1), length 84)
    192.168.20.30 > 192.168.10.20: ICMP echo reply, id 31773, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

Agora são três camadas. O pacote externo tem **112 bytes**, com `proto GRE (47)`. Dentro dele, o GRE
informa `length 92` e `key=0x2a`, que é 42 em hexadecimal. Dentro disso, o mesmo ping de 84 bytes de
antes. **112 − 84 = 28 bytes de túnel**: 20 de IP externo e 8 de GRE, dos quais 4 são a chave. O MTU do
túnel foi de 1480 para 1472 pelo mesmo motivo.

## Para que serve a chave

**A chave do GRE separa dois túneis entre o mesmo par de endereços.** Dois roteadores podem manter
vários túneis GRE ao mesmo tempo, para clientes diferentes ou domínios de roteamento diferentes, e os
cabeçalhos externos seriam idênticos. A chave é como cada pacote diz a qual túnel pertence.

Não é senha. Ela viaja em texto claro, o `tcpdump` a imprimiu, e qualquer um no caminho pode lê-la e
copiá-la. O que ela faz é fazer uma divergência falhar. Reinicie a ponta de `branch` com chave 43 enquanto
`hq` fica com 42, faça um ping do laptop, depois volte para 42 e faça outro ping:

```
ana@netlab:~$ sudo bash netlab.sh kill branch tunnel.py
ana@branch:~$ sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 43 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@laptop:~$ ping -c 2 -W 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1022ms

ana@netlab:~$ sudo bash netlab.sh kill branch tunnel.py
ana@branch:~$ sudo setsid tunnel.py gre tun0 198.51.100.2 203.0.113.2 42 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@laptop:~$ ping -c 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=1.58 ms

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.576/1.576/1.576/0.000 ms
```

Com a chave errada, **nada informa erro**. Os pacotes chegam a `branch`, `branch` vê uma chave que não
espera e os descarta, e o laptop só vê silêncio. Esse silêncio é o sintoma comum de um túnel cujas duas
pontas discordam de alguma coisa, e a aula 4 o encontra de novo com o WireGuard.

| | IP-in-IP | GRE |
|---|---|---|
| protocolo IP | 4 | 47 |
| bytes acrescentados | 20 | 24, ou 28 com chave |
| leva | só IPv4 | IPv4, IPv6, multicast, Ethernet |
| separa túneis | não | sim, pela chave |
| criptografa | não | não |
