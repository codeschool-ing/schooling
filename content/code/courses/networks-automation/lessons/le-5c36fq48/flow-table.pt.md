---
title: Um switch com a tabela vazia
version: 1
---

O `sw1` tem uma bridge, `br0`, com as três portas, e nada mais:

```
ana@sw1:~$ ovs-vsctl show
9ee14f25-2944-48ee-ae8e-d8cfbeac168e
    Bridge br0
        fail_mode: secure
        datapath_type: netdev
        Port p3
            Interface p3
        Port br0
            Interface br0
                type: internal
        Port p2
            Interface p2
        Port p1
            Interface p1
```

`fail_mode: secure` quer dizer que o switch não volta a se comportar como um switch comum com
aprendizado quando não tem controlador. **Ele encaminha exatamente o que a sua tabela de flows
diz**, e a tabela está vazia:

```
ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0
OFPST_FLOW reply (OF1.3) (xid=0x2):
ana@h1:~$ ping -c 2 -W 1 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1027ms
```

Nem um pacote passou. Um flow é um **match**, a quais campos de um pacote ele se aplica, uma
**prioridade**, qual flow vence quando vários casam, e **ações**, o que fazer com o pacote. O
`ovs-ofctl` os escreve direto no switch, dois aqui, um para cada direção entre as portas 1 e 2:

```
ana@sw1:~$ ovs-ofctl -O OpenFlow13 add-flow br0 "priority=10,in_port=1,actions=output:2" && ovs-ofctl -O OpenFlow13 add-flow br0 "priority=10,in_port=2,actions=output:1"
ana@h1:~$ ping -c 2 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.
From 203.0.113.129 icmp_seq=1 Destination Host Unreachable
64 bytes from 203.0.113.130: icmp_seq=2 ttl=64 time=1.33 ms

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 1 received, +1 errors, 50% packet loss, time 999ms
rtt min/avg/max/mdev = 1.333/1.333/1.333/0.000 ms
ana@h1:~$ ping -c 2 -W 1 203.0.113.131
PING 203.0.113.131 (203.0.113.131) 56(84) bytes of data.

--- 203.0.113.131 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1023ms
```

O primeiro echo request falhou no ARP, o h1 não recebeu a tempo a resposta à sua pergunta, e o
segundo passou. O h3, na porta 3, não tem flow nenhum e está inalcançável. A tabela agora tem
contadores:

```
ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0
OFPST_FLOW reply (OF1.3) (xid=0x2):
 cookie=0x0, duration=3.098s, table=0, n_packets=5, n_bytes=266, priority=10,in_port=1 actions=output:2
 cookie=0x0, duration=3.090s, table=0, n_packets=2, n_bytes=140, priority=10,in_port=2 actions=output:1
ana@sw1:~$ ovs-ofctl -O OpenFlow13 del-flows br0
```

**Cada flow conta os pacotes e bytes que casaram com ele**, que é o switch dizendo, flow por flow,
o que fez. Depois os flows são apagados de novo, para o controlador escrever.

Isto é configuração como encaminhamento: nenhum protocolo de roteamento, nenhum aprendizado de MAC,
nada dentro do switch decidindo coisa alguma. Escrever cada flow à mão seria a digitação da aula 1
numa escala maior. O controlador é o programa que os escreve.
