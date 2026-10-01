---
title: How many hosts fit in a range
version: 1
---

The question a plan asks most is how many machines a range holds. The answer comes from the host
bits alone. **A prefix of length n leaves h = 32 − n host bits, which make 2^h addresses, and 2^h − 2
of them are for hosts**, because the network and broadcast addresses are taken. sales1's `/25` has 7
host bits: 2^7 = 128 addresses and 126 hosts, the `Hosts/Net: 126` this lesson began with.

The common mistake is to stop at 2^h. A `/26` holds 64 addresses and only 62 machines. The second
mistake comes one step later: on a LAN, one of those 62 is the router's own interface, so a `/26` is
62 addresses for 61 PCs, printers and phones plus the gateway.

From `/24` down to the smallest:

| prefix | mask | host bits | addresses | hosts |
|---|---|---|---|---|
| `/24` | 255.255.255.0 | 8 | 256 | 254 |
| `/25` | 255.255.255.128 | 7 | 128 | 126 |
| `/26` | 255.255.255.192 | 6 | 64 | 62 |
| `/27` | 255.255.255.224 | 5 | 32 | 30 |
| `/28` | 255.255.255.240 | 4 | 16 | 14 |
| `/29` | 255.255.255.248 | 3 | 8 | 6 |
| `/30` | 255.255.255.252 | 2 | 4 | 2 |
| `/31` | 255.255.255.254 | 1 | 2 | 2, on a point-to-point link |
| `/32` | 255.255.255.255 | 0 | 1 | 1, a single host |

**Each step of one bit halves the range.** Going the other way, each bit shorter doubles it: a `/23`
is 512 addresses, a `/22` is 1024, a `/20` is 4096 and a `/16` is 65,536.

The last three rows deserve their outputs. The link between r1 and r2 in this lab is a `/30`:

```
ana@sales1:~$ ipcalc -b 10.20.32.224/30
Address:   10.20.32.224         
Netmask:   255.255.255.252 = 30 
Wildcard:  0.0.0.3              
=>
Network:   10.20.32.224/30      
HostMin:   10.20.32.225         
HostMax:   10.20.32.226         
Broadcast: 10.20.32.227         
Hosts/Net: 2                     Class A, Private Internet

```

Four addresses: `.224` the network, `.227` the broadcast, and two hosts in between. r1 has `.225` and
r2 has `.226`. **A link between two routers needs exactly two addresses**, and a `/30` gives exactly
two, at the cost of four. That cost is why the next prefix exists:

```
ana@sales1:~$ ipcalc -b 10.20.32.224/31
Address:   10.20.32.224         
Netmask:   255.255.255.254 = 31 
Wildcard:  0.0.0.1              
=>
Network:   10.20.32.224/31      
HostMin:   10.20.32.224         
HostMax:   10.20.32.225         
Hosts/Net: 2                     Class A, Private Internet, PtP Link RFC 3021

```

A `/31` has two addresses and ipcalc calls both of them hosts, with no `Broadcast` line at all and the
note `PtP Link RFC 3021`. RFC 3021 (2000) made the exception: **on a point-to-point link, where there
is nobody to broadcast to but the other end, a `/31` may use both addresses**. It halves the address
cost of every router-to-router link, and most routers accept it; on a LAN it would leave no room for
anything else and is never used.

```
ana@sales1:~$ ipcalc -b 10.20.32.10/32
Address:   10.20.32.10          
Netmask:   255.255.255.255 = 32 
Wildcard:  0.0.0.0              
=>
Hostroute: 10.20.32.10          
Hosts/Net: 1                     Class A, Private Internet

```

A `/32` is one address, and ipcalc names it a `Hostroute`. Nobody builds a LAN of one, but `/32` is
everywhere in routing: a route to exactly one machine, a loopback address on a router that other
routers reach, a single address in a firewall rule.

Choosing a size is the table read backwards. **Count the machines, add one for the gateway, and take
the smallest range whose host count is at least that.** A LAN of 50 machines needs 51 addresses: a
`/27` holds 30, too few, and a `/26` holds 62, so it is a `/26`. Lesson 13 does this for a whole
plan, with several LANs of different sizes inside one block, and puts the largest first for a reason
that lesson explains.
