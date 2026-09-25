---
title: Chamado: "a internet caiu"
version: 1
---

O laptop não alcança nada. O primeiro erro fala de um nome, e engana:

```
ana@laptop:~$ ping -c 2 www.example.com
ping: www.example.com: Temporary failure in name resolution
ana@laptop:~$ ip -br addr show eth0
eth0@if749       UP             192.168.10.20/24 
ana@laptop:~$ ip route
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
ana@laptop:~$ ping -c 2 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.490 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=64 time=0.125 ms

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1009ms
rtt min/avg/max/mdev = 0.125/0.307/0.490/0.182 ms
ana@laptop:~$ ping -c 2 192.0.2.80
ping: connect: Network is unreachable
ana@laptop:~$ sudo ip route add default via 192.168.10.1
ana@laptop:~$ ping -c 2 www.example.com
PING www.example.com (192.0.2.80) 56(84) bytes of data.
64 bytes from www.example.com (192.0.2.80): icmp_seq=1 ttl=61 time=0.257 ms
64 bytes from www.example.com (192.0.2.80): icmp_seq=2 ttl=61 time=0.117 ms

--- www.example.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.117/0.187/0.257/0.070 ms
```

`Temporary failure in name resolution` soa como DNS. Subir a escada diz outra coisa. A interface está
`UP` com o endereço. O `ip route` tem só a rede do escritório, `192.168.10.0/24`, e **nenhuma linha
`default via`**: o laptop não conhece caminho nenhum para fora da própria rede. O gateway responde ao
`ping`, então o cabo e o roteador estão bem. `192.0.2.80` falha na hora com `Network is unreachable`: é
o próprio kernel do laptop recusando, porque não tem rota por onde mandar o pacote.

O erro de DNS era consequência. O servidor DNS, `198.51.100.53`, também fica fora da rede do escritório,
e também não era alcançável. Pôr a rota padrão de volta consertou os dois. **Num PC de verdade a rota
vem do DHCP**, então o conserto costuma ser renovar a concessão ou tirar uma configuração digitada à mão,
em vez de um comando `ip route`.
