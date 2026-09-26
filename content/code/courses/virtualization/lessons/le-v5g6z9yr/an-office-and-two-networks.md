---
title: An office, and two more networks
version: 1
---

To see a guest from the other side, there has to be another side. On your own computer it is your real
network. The computer this course was recorded on has no card of its own to lend, so `lab.sh office`
builds a small office network instead. It is a bridge called `lan0`, where host is `10.0.0.1`, and one other
device on it, a **printer** at `10.0.0.50` that answers web requests, writes down who asked, and runs
the office's DHCP:

```
ana@host:~$ ip -br addr show lan0
lan0             UP             10.0.0.1/24 
ana@host:~$ curl -sS http://10.0.0.50/
office printer: ready
```

Then two libvirt networks, each described in a few lines of XML. `lan` is **bridged**: it joins the
guests to `lan0` itself, the office network, with no NAT and no DHCP of libvirt's own. `isolated` has an
address and a DHCP range but **no `forward` element**, so nothing it carries goes anywhere else:

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

On a real host, a bridged network is joined to the host's real card, and the bridge has to exist
first: Ubuntu makes one with netplan, Proxmox made `vmbr0` at installation, lesson 6. One guest was
then made on each network: `vmn` on `default`, `vmb` on `lan`, `vmi` on `isolated`.
