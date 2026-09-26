---
title: The lab’s network
version: 1
---

The network first, described in the same few lines as lesson 11's isolated one:

```
ana@host:~$ cat labnet.xml
<network>
  <name>labnet</name>
  <bridge name="virbr2"/>
  <ip address="10.20.0.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.20.0.10" end="10.20.0.50"/>
    </dhcp>
  </ip>
</network>
ana@host:~$ virsh net-define labnet.xml && virsh net-start labnet && virsh net-autostart labnet
Network labnet defined from labnet.xml

Network labnet started

Network labnet marked as autostarted
```

No `forward` element, so nothing leaves it; its own range of addresses, `10.20.0.0/24`, so it cannot be
confused with any other network on the host; and **`net-autostart`**, so the lab's network comes back
by itself when the host restarts. A network that has to be started by hand is a lab that does not work
on the morning you need it.
