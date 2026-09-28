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

Num roteador Linux é um comando, e no kernel deste laboratório esse comando falha:

```
ana@hq:~$ sudo ip link add gre1 type gre local 203.0.113.2 remote 198.51.100.2 key 42
Error: Unknown device type.
```

`Unknown device type` quer dizer que o kernel não tem o módulo de GRE, não que o comando esteja errado.
Então o laboratório roda o `tunnel.py` de novo, em modo GRE, com os mesmos endereços e chave 42:

```
ana@hq:~$ sudo setsid tunnel.py gre tun0 203.0.113.2 198.51.100.2 42 & sleep 1; sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1472 up && sudo ip route add 192.168.20.0/24 via 10.0.0.2
ana@isp:~$ sudo tcpdump -n -t -v -i eth0 -c 2 ip proto 47
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP (tos 0x0, ttl 64, id 61232, offset 0, flags [DF], proto GRE (47), length 112)
    203.0.113.2 > 198.51.100.2: GREv0, Flags [key present], key=0x2a, length 92
	IP (tos 0x0, ttl 63, id 15631, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.10.20 > 192.168.20.30: ICMP echo request, id 59237, seq 1, length 64
IP (tos 0x0, ttl 63, id 1189, offset 0, flags [DF], proto GRE (47), length 112)
    198.51.100.2 > 203.0.113.2: GREv0, Flags [key present], key=0x2a, length 92
	IP (tos 0x0, ttl 63, id 59331, offset 0, flags [none], proto ICMP (1), length 84)
    192.168.20.30 > 192.168.10.20: ICMP echo reply, id 59237, seq 1, length 64
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
copiá-la. O que ela faz é fazer uma divergência falhar. `branch` foi reiniciado com chave 43 enquanto
`hq` ficou com 42, e depois voltou ao normal:

```
ana@laptop:~$ ping -c 2 -W 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1001ms

ana@laptop:~$ ping -c 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=0.518 ms

--- 192.168.20.30 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.518/0.518/0.518/0.000 ms
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
