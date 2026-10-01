---
title: Classes A, B and C, and why nobody plans with them
version: 1
---

Until 1993 the first bits of an address decided where its network part ended. Nobody chose a mask:
an address starting with the bit 0 had an 8-bit network part, one starting with 10 had 16, and one
starting with 110 had 24. That scheme is called **classful addressing**, and the internet stopped
using it more than thirty years ago. It is still worth knowing for two reasons: tools still print
it, and people still say "a class C" when they mean a /24.

| class | first bits | first octet | network part | what it was for |
|---|---|---|---|---|
| A | `0` | 0 to 127 | 8 bits, `/8` | 126 huge networks |
| B | `10` | 128 to 191 | 16 bits, `/16` | medium networks |
| C | `110` | 192 to 223 | 24 bits, `/24` | small networks |
| D | `1110` | 224 to 239 | none | multicast groups |
| E | `1111` | 240 to 255 | none | reserved |

The first-octet ranges fall out of the first bits. A class B address starts with `10`, so its first
octet goes from `10000000` (128) to `10111111` (191). **The class is read off the first octet, and
you can do it in your head**: 172 is between 128 and 191, so 172.16.5.4 is class B.

`ipcalc` still prints the class. Here it is on a class B address:

```
ana@pc1:~$ ipcalc -b 172.16.5.4
Address:   172.16.5.4           
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   172.16.5.0/24        
HostMin:   172.16.5.1           
HostMax:   172.16.5.254         
Broadcast: 172.16.5.255         
Hosts/Net: 254                   Class B, Private Internet

```

Look at the mask. **Given no mask, this ipcalc assumes `/24` for every address**, whatever the class
says, so the output reads `Class B` beside a `/24` network. A router working by the classful rules
would have taken 172.16.5.4 as part of 172.16.0.0/16. The class has become a label the calculator
computes from the first bits, and it no longer decides anything. The same command on 10.1.2.3 and
192.168.1.1 printed `Class A` and `Class C`, each beside the same `/24`.

The classes were dropped because their sizes jump. A class C network holds 254 hosts, a class B
holds 65,534 and a class A holds 16,777,214, with nothing in between. An organisation with 300
machines was too big for a C, so it was given a B and left more than 65,000 addresses unused. Class
B networks ran short in the early 1990s, and the alternative, handing out several class C networks
instead, put a separate route for each one into every router on the internet. **CIDR (Classless
Inter-Domain Routing, 1993) let the mask fall on any bit**, so the organisation with 300 machines
gets a `/23` of 510 hosts, and lesson 12 is the arithmetic of it.

Class D is the exception that is still in force. Addresses from 224 to 239 are **multicast**
groups: a packet sent to one is delivered to every machine that joined the group, and to nobody
else. ipcalc on one of them:

```
ana@pc1:~$ ipcalc -b 224.0.0.5
Address:   224.0.0.5            
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   224.0.0.0/24         
HostMin:   224.0.0.1            
HostMax:   224.0.0.254          
Broadcast: 224.0.0.255          
Hosts/Net: 254                   Class D, Multicast

```

`Class D, Multicast` is right. The `HostMin`, `HostMax` and `Broadcast` lines above it are not
meaningful: a multicast address is a group, with no hosts inside it, and the calculator applied the
arithmetic of a `/24` anyway because it was asked to. **A tool computes what it is asked; it does not
know whether the question makes sense.** 224.0.0.5 itself is the group OSPF routers use to talk to
each other, and lesson 16 is about OSPF.

Class E, from 240 upwards, was reserved for future use and never given out. What survives of the
classes in daily work is mostly vocabulary, and the first-octet ranges of the private blocks in the
next section.
