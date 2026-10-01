---
title: Quando o controlador para
version: 1
---

O controlador foi parado no fim da seção anterior. Dois segundos depois, o switch fica sabendo:

```
ana@sw1:~$ ovs-vsctl list controller | grep -E "^(target|is_connected)"
is_connected        : false
target              : "tcp:192.0.2.10:6653"
ana@h1:~$ ping -c 2 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.
64 bytes from 203.0.113.130: icmp_seq=1 ttl=64 time=0.321 ms
64 bytes from 203.0.113.130: icmp_seq=2 ttl=64 time=0.188 ms

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1029ms
rtt min/avg/max/mdev = 0.188/0.254/0.321/0.066 ms
```

**O tráfego que já tem flows continua passando.** O switch ainda guarda o que o controlador
escreveu, e no modo `secure` continua usando isso. É assim que um controlador pode ser reiniciado
para um upgrade sem uma queda.

Trinta e cinco segundos depois, sem tráfego nesse meio-tempo:

```
ana@h1:~$ ping -c 2 -W 1 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1026ms

ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0
OFPST_FLOW reply (OF1.3) (xid=0x2):
 cookie=0x0, duration=53.805s, table=0, n_packets=2, n_bytes=196, priority=100,ip,nw_src=203.0.113.131,nw_dst=203.0.113.129 actions=drop
 cookie=0x0, duration=53.805s, table=0, n_packets=10, n_bytes=644, priority=0 actions=CONTROLLER:65535
```

**Os flows aprendidos expiraram, e nada os substituiu.** O idle timeout removeu os flows de h1 e
h2, o table-miss mandou o pacote seguinte para um controlador que não está lá, e o pacote não foi a
lugar nenhum. A regra de descarte continua na tabela, já que não tem timeout; a rede agora aplica
sua política e não encaminha mais nada.

Essa é a troca que o SDN faz, numa captura só. Uma rede de roteadores rodando OSPF continua
funcionando quando qualquer um deles falha, porque cada um decide. Uma rede comandada por um
controlador **depende do controlador**, por isso controladores em produção rodam em clusters de
três ou mais, com os switches conectados a vários ao mesmo tempo; e a escolha entre `secure`, que
mantém as regras do controlador e não faz mais nada, e `standalone`, que volta a se comportar como
um switch comum, é uma decisão sobre qual falha é pior.
