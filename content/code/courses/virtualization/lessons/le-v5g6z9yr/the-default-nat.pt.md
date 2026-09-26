---
title: A rede padrão é NAT
version: 1
---

Todo convidado até aqui ficou na rede do libvirt chamada `default`. Eis o que ela é:

```
ana@host:~$ virsh net-list --all
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes

ana@host:~$ virsh net-dumpxml default | grep -E "<(forward|bridge|ip|range) "
  <forward mode='nat'>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
      <range start='192.168.122.2' end='192.168.122.254'/>
ana@host:~$ sudo iptables -t nat -S | grep 192.168.122
-A LIBVIRT_PRT -s 192.168.122.0/24 -d 224.0.0.0/24 -j RETURN
-A LIBVIRT_PRT -s 192.168.122.0/24 -d 255.255.255.255/32 -j RETURN
-A LIBVIRT_PRT -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p tcp -j MASQUERADE --to-ports 1024-65535
-A LIBVIRT_PRT -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p udp -j MASQUERADE --to-ports 1024-65535
-A LIBVIRT_PRT -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
```

`forward mode='nat'`: os convidados saem pelo host. A `virbr0` é o switch, e o host é `192.168.122.1`
nela, o roteador dos convidados, aula 3. O `range` é o que o DHCP do libvirt distribui.

E o NAT em si são aquelas três linhas `MASQUERADE` no firewall do host: **tudo o que vem de
`192.168.122.0/24` indo para qualquer outro lugar sai com o endereço do host como remetente.** As duas
linhas acima delas deixam multicast e broadcast em paz. É esse o truque inteiro, e o VirtualBox e o
VMware fazem o mesmo com código próprio em vez do firewall do host.
