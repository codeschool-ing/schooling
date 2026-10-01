---
title: Loopback, the machine talking to itself
version: 1
---

Every machine has an interface with no cable behind it. It is called `lo`, for **loopback**, and a
packet sent to it never leaves the machine: the kernel hands it straight back to itself. pc1's:

```
ana@pc1:~$ ip addr show lo
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
```

The address is `127.0.0.1`, with a mask of `/8`. **The whole of `127.0.0.0/8` is loopback**, all
16,777,216 addresses of it, not only the one everybody types. `scope host` says the address means
something only inside this machine, and `mtu 65536` is a hint that no Ethernet is involved: a
virtual interface can move packets far larger than a cable's 1500 bytes. The `inet6 ::1/128` line
is IPv6's loopback, which is a single address rather than a block.

Ping the address everybody knows, and then one nobody configured:

```
ana@pc1:~$ ping -c 1 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=9.14 ms

--- 127.0.0.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 9.143/9.143/9.143/0.000 ms
ana@pc1:~$ ping -c 1 127.45.6.7
PING 127.45.6.7 (127.45.6.7) 56(84) bytes of data.
64 bytes from 127.45.6.7: icmp_seq=1 ttl=64 time=0.813 ms

--- 127.45.6.7 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.813/0.813/0.813/0.000 ms
```

Both answered. Nothing on pc1 was given `127.45.6.7`, but the `/8` on `lo` covers it, so the
kernel answers for it as it does for `127.0.0.1`. The two times, 9.14 ms and 0.813 ms, are a
measurement of this lab's virtual machine and say nothing about loopback in general. And ipcalc
agrees about what the range is:

```
ana@pc1:~$ ipcalc -b 127.0.0.1
Address:   127.0.0.1            
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   127.0.0.0/24         
HostMin:   127.0.0.1            
HostMax:   127.0.0.254          
Broadcast: 127.0.0.255          
Hosts/Net: 254                   Class A, Loopback

```

As with every address in this lesson, the `/24` and its 254 hosts are ipcalc's assumption, not the
range. The label at the end, `Loopback`, is the part that is right.

**A program listening on `127.0.0.1` accepts connections only from the same machine.** That is how
a database on a web server is kept away from the network: it listens on loopback, the web
application on the same machine connects to it there, and nothing outside can reach the port at all.
The name `localhost` points to `127.0.0.1` through the machine's `/etc/hosts`, so the two are the
same thing written differently.

The wrong idea worth naming here is that pinging `127.0.0.1` tests the network card. It tests no
card at all. A reply proves that the machine's TCP/IP software is running, and nothing about the
cable, the switch or the network. **A machine with its cable unplugged still answers a ping to
`127.0.0.1`**, which makes it a poor first test when the complaint is that the network is down: it
can only ever say yes.

Loopback also explains a confusion that turns up in support calls. When somebody reports that a
service "works on the server but not from my machine", the service is often listening on
`127.0.0.1` only. Tested on the server, it answers; tested from anywhere else, the connection is
refused, because nothing listens on the server's real address. This lesson's last section shows,
with `ss`, the addresses this office's server listens on.
