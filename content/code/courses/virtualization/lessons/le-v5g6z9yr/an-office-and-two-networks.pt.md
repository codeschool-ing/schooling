---
title: Um escritório, e mais duas redes
version: 1
---

Para ver um convidado pelo outro lado, precisa existir um outro lado. No seu computador, é a sua rede de
verdade. O computador em que este curso foi gravado não tem placa própria para emprestar, então o
`lab.sh office` monta uma rede de escritório pequena no lugar. É uma ponte chamada `lan0`, onde o host é
`10.0.0.1`, e um outro aparelho nela, uma **impressora** em `10.0.0.50` que responde a pedidos web,
anota quem pediu e roda o DHCP do escritório:

```
ana@host:~$ ip -br addr show lan0
lan0             UP             10.0.0.1/24 
ana@host:~$ curl -sS http://10.0.0.50/
office printer: ready
```

Depois, duas redes do libvirt, cada uma descrita em algumas linhas de XML. A `lan` é **em ponte**: une
os convidados à própria `lan0`, a rede do escritório, sem NAT e sem DHCP do libvirt. A `isolated` tem
endereço e faixa de DHCP mas **nenhum elemento `forward`**, então nada que ela carrega vai para outro
lugar:

```
ana@host:~$ cat lan.xml
<network>
  <name>lan</name>
  <forward mode="bridge"/>
  <bridge name="lan0"/>
</network>
ana@host:~$ virsh net-define lan.xml && virsh net-start lan
Network lan defined from lan.xml

Network lan started

ana@host:~$ cat isolated.xml
<network>
  <name>isolated</name>
  <bridge name="virbr1"/>
  <ip address="10.10.10.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.10.10.10" end="10.10.10.50"/>
    </dhcp>
  </ip>
</network>
ana@host:~$ virsh net-define isolated.xml && virsh net-start isolated
Network isolated defined from isolated.xml

Network isolated started

ana@host:~$ virsh net-list
 Name       State    Autostart   Persistent
---------------------------------------------
 default    active   yes         yes
 isolated   active   no          yes
 lan        active   no          yes
```

Num host de verdade, uma rede em ponte é unida à placa real do host, e a ponte precisa existir antes: o
Ubuntu faz uma com o netplan, o Proxmox fez a `vmbr0` na instalação, aula 6. Depois foi feito um
convidado em cada rede: a `vmn` na `default`, a `vmb` na `lan`, a `vmi` na `isolated`.
