---
title: Alcançando um ao outro
version: 1
---

O único jeito de host e convidado se alcançarem que você escolhe usar é a rede. De dentro:

```
ana@vm1:~$ ip route
default via 192.168.122.1 dev enp1s0 proto dhcp src 192.168.122.117 metric 100 
192.168.122.0/24 dev enp1s0 proto kernel scope link src 192.168.122.117 metric 100 
192.168.122.1 dev enp1s0 proto dhcp scope link src 192.168.122.117 metric 100 
ana@host:~$ ip -br addr show virbr0
virbr0           UP             192.168.122.1/24 
ana@vm1:~$ nc -zv -w 3 192.168.122.1 53
Connection to 192.168.122.1 53 port [tcp/domain] succeeded!
```

A rota padrão do convidado é `192.168.122.1`, e esse endereço é do próprio host, no `virbr0`, o switch
virtual da rede `default`. Então **o host é o roteador do convidado**, e todo pacote que a vm1 manda
para qualquer lugar passa primeiro pelo host. A porta 53 respondeu: o libvirt roda um pequeno servidor
DNS e DHCP para a rede nesse endereço, e foi ele que deu à vm1 o `192.168.122.117`. O outro sentido não precisa de
demonstração, porque todo `ssh vm1` deste curso é o host alcançando o convidado.

Guarde isso para a aula 15: **um convidado sempre alcança o endereço do próprio host na rede dele**, e
qualquer serviço que o host rode ali responde ao convidado também. Num laptop, é assim que um
convidado feito para experimentos acaba conversando com algo no host que nunca deveria ver.
