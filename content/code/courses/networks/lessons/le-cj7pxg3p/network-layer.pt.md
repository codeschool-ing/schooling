---
title: Camada 3: um endereço e uma rota
version: 1
---

A camada 3 leva um pacote à máquina certa através de redes, e o endereço dela é o **endereço IP**. O
laptop tem um, com um comprimento de prefixo depois da barra:

```
ana@laptop:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if107       UP             192.168.10.20/24 
```

`192.168.10.20/24` diz duas coisas. O endereço é `192.168.10.20`, e os primeiros 24 bits,
`192.168.10`, dão nome à **rede** a que ele pertence. Todo endereço que começa com `192.168.10` está
no mesmo enlace e é alcançado direto, com ARP, como foi o servidor. Qualquer outro não está, e vai
para um **roteador**. (Trabalhar com prefixos é assunto do curso networks-addressing; aqui, `/24`
quer dizer "os três primeiros números coincidem".)

Qual roteador é a resposta da **tabela de rotas**:

```
ana@laptop:~$ ip route
default via 192.168.10.1 dev eth0 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
ana@laptop:~$ ip route get 192.0.2.80
192.0.2.80 via 192.168.10.1 dev eth0 src 192.168.10.20 uid 1000 
    cache 
ana@laptop:~$ ping -c 3 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.413 ms
64 bytes from 192.0.2.80: icmp_seq=2 ttl=61 time=0.104 ms
64 bytes from 192.0.2.80: icmp_seq=3 ttl=61 time=0.105 ms

--- 192.0.2.80 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2028ms
rtt min/avg/max/mdev = 0.104/0.207/0.413/0.145 ms
```

Duas linhas, lidas da mais específica. `192.168.10.0/24 dev eth0` é o escritório: mande direto para
fora. `default via 192.168.10.1` é todo o resto: entregue ao **gateway**, o roteador do escritório. O
`ip route get` pergunta à tabela sobre um endereço, e para o servidor web a resposta é *via
192.168.10.1*.

**O ping atravessou roteadores, e o TTL diz quantos.** Um pacote sai com um *time to live*, 64 no
Linux, e cada roteador tira um antes de encaminhá-lo. A resposta do servidor no escritório chegou com
`ttl=64`, sem atravessar nenhum; a resposta de `192.0.2.80` chegou com `ttl=61`, então atravessou
três. Um pacote cujo TTL chega a zero é descartado, e é isso que impede um pacote de girar para
sempre quando as rotas formam um laço.

O `traceroute` usa essa regra para dar nome aos roteadores. Ele manda pacotes com TTL 1, depois 2,
depois 3, e cada roteador que descarta um avisa:

```
ana@laptop:~$ traceroute -n 192.0.2.80
traceroute to 192.0.2.80 (192.0.2.80), 30 hops max, 60 byte packets
 1  192.168.10.1  0.235 ms  0.009 ms  0.004 ms
 2  203.0.113.1  0.547 ms  0.108 ms  0.296 ms
 3  198.51.100.254  0.283 ms  0.181 ms  0.201 ms
 4  192.0.2.80  0.301 ms  0.184 ms  0.103 ms
```

Quatro linhas: o roteador do escritório, o roteador do provedor, um roteador no núcleo do provedor e o
próprio servidor web, cada um medido três vezes. Os tempos são os do laboratório, um computador
falando consigo mesmo; numa conexão de verdade, só a segunda linha levaria vários milissegundos.
