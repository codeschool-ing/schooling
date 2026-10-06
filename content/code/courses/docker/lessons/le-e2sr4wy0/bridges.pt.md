---
title: A bridge padrão
version: 1
---

**A aula 4 disse que cada container ganha um namespace de rede próprio: interfaces, endereços e rotas
próprios.** Esta aula olha como esses namespaces são ligados entre si, e à máquina. Um daemon novo tem
três redes:

```
ana@vm:~$ docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
2d949de13bd0   bridge    bridge    local
ff3f48e4f5cb   host      host      local
25e410e18a45   none      null      local
ana@vm:~$ ip -brief addr show docker0
docker0          DOWN           172.17.0.1/16 
```

`bridge` é para onde os containers vão quando nada mais é dito; `host` e `none` são as duas pontas da
escala, no fim desta aula. **O `docker0` é a própria bridge**: um switch virtual no kernel do host, com o
endereço `172.17.0.1`, e `DOWN` porque nada está plugado nele ainda.

## Um cabo chamado veth

```
ana@vm:~$ docker run -d --name box-a alpine:3.22 sleep 600
54b006057a096a03466f1b5f3692e09d14972e544d742ae9aaa8383aacd757e3
ana@vm:~$ ip -brief link | grep -E "^(docker0|veth)"
docker0          UP             46:f7:bb:9f:ee:1e <BROADCAST,MULTICAST,UP,LOWER_UP> 
veth47fa4d1@if2  UP             9a:82:17:c6:b3:8f <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@vm:~$ docker exec box-a ip addr show eth0
2: eth0@if114: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether f2:cd:14:8d:8b:55 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
ana@vm:~$ docker exec box-a ip route
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 scope link  src 172.17.0.2 
```

**Iniciar um container plugou um cabo.** Um *par veth* são duas interfaces virtuais ligadas como as duas
pontas de um cabo: uma ponta, `eth0`, vai para o namespace do container com o endereço `172.17.0.2`; a
outra, `veth…` no host, é plugada no `docker0`, que agora está `UP`. A rota padrão do container vai para
`172.17.0.1`, então **o host é o gateway do container**, e a saída dele para qualquer outro lugar.

## Endereço, mas não nome

```
ana@vm:~$ docker run -d --name box-b alpine:3.22 sleep 600
596fcaebb8f540709e20c5a14c9d118297b8857e17ba9a7445007459b5e18630
ana@vm:~$ docker exec box-b ping -c 1 -W 1 box-a
ping: bad address 'box-a'
ana@vm:~$ docker exec box-b ping -c 1 -W 1 $(docker inspect box-a --format "{{.NetworkSettings.Networks.bridge.IPAddress}}")
PING 172.17.0.2 (172.17.0.2): 56 data bytes
64 bytes from 172.17.0.2: seq=0 ttl=64 time=0.472 ms

--- 172.17.0.2 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 0.472/0.472/0.472 ms
```

O `box-b` não acha o `box-a` pelo nome, `bad address`, e o alcança na hora pelo endereço. **A bridge
padrão não resolve nomes entre containers**, por motivos históricos que o Docker mantém por
compatibilidade. Os endereços são distribuídos no início e podem mudar no próximo, então um endereço
num arquivo de configuração é um bug esperando um reinício. A solução é uma rede própria, e é a
próxima etapa.
