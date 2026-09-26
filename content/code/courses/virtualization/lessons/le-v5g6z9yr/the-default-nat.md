---
title: The default network is NAT
version: 1
---

Every guest so far has been on libvirt's network called `default`. Here is what it is:

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

`forward mode='nat'`: guests go out through the host. `virbr0` is the switch, and the host is
`192.168.122.1` on it, the guests' router, lesson 3. The `range` is what libvirt's DHCP hands out.

And the NAT itself is those three `MASQUERADE` lines in the host's firewall: **anything from
`192.168.122.0/24` going anywhere else leaves with the host's address as its sender.** The two lines
above them leave multicast and broadcast alone. That is the whole trick, and VirtualBox and VMware do
the same with their own code instead of the host's firewall.
