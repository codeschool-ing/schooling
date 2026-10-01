---
title: /27, a mask written as a count
version: 1
---

Writing `255.255.255.224` every time is slow and easy to get wrong, and since a mask is a run of
ones followed by zeros, one number describes it completely: how many ones. **The prefix length,
written after a slash, is the number of ones in the mask.** `10.20.32.200/27` means the address
`10.20.32.200` with a mask of 27 ones. ipcalc prints both forms side by side, which makes it a good
place to practise the conversion. ops1's LAN:

```
ana@sales1:~$ ipcalc -b 10.20.32.200/27
Address:   10.20.32.200         
Netmask:   255.255.255.224 = 27 
Wildcard:  0.0.0.31             
=>
Network:   10.20.32.192/27      
HostMin:   10.20.32.193         
HostMax:   10.20.32.222         
Broadcast: 10.20.32.223         
Hosts/Net: 30                    Class A, Private Internet

```

`Netmask: 255.255.255.224 = 27`. To convert by hand, split 27 into whole octets and a remainder: 27
is 24 + 3, so three octets of 255 and then an octet with three ones, `11100000`, which is 128 + 64 + 32
= 224. Going the other way, count the ones: 255 is eight, 224 is three, so 8 + 8 + 8 + 3 = 27.

The values worth knowing by heart are the nine an octet can take, from the previous section, paired
with how many ones each one holds:

| ones in the octet | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| value of the octet | 0 | 128 | 192 | 224 | 240 | 248 | 252 | 254 | 255 |

So `/26` is `255.255.255.192`, `/20` is `255.255.240.0` (16 + 4: two full octets and four ones), and
`/12` is `255.240.0.0`. **Any prefix is two numbers away from its mask: how many full octets, and
which of the nine values comes after them.**

The slash notation has a name, **CIDR**, Classless Inter-Domain Routing, and it arrived in 1993 to
replace the classes of lesson 8. Before it, the mask was implied by the first bits of the address
and nobody had to write one. After it, the mask could fall on any bit, so it had to travel with the
address everywhere: in configurations, in routing tables, in the announcements routers make to each
other. The class still printed at the end of this output, `Class A`, describes `10.x` under the old
rules and says nothing about this `/27`.

The prefix is not only a property of an address on an interface; **a route carries one too**, and
that is where CIDR mattered most. In this lab r1 holds the three LANs as three separate routes,
`10.20.32.0/25`, `10.20.32.128/26` and `10.20.32.192/27`, while r2 upstream holds a single route,
`10.20.32.0/24`, that covers all three. One shorter prefix standing for several longer ones is
called summarisation, and lesson 13 builds it and shows what it costs.

A last reading of the prefix that is easy to forget: **a longer prefix is a smaller network**. A `/27`
has more ones than a `/24`, so fewer bits are left for hosts, and it holds fewer addresses. When a
routing table has two routes that both contain a destination, the router uses the one with the
longer prefix, because it is the more specific of the two. Lesson 14 reads that rule in a real
table.
