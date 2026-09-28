---
title: A DNS query and its answer
version: 1
---

A DNS lookup is the smallest complete conversation on a network: **one UDP packet out, one back, and
nothing to open or close.** Lesson 4 of `networks` explained what it asks. Here it is on the wire.

The laptop looked up a name that exists and a name that does not, while a capture printed five fields
of each DNS packet: the transaction id, whether it is a response, the reply code, the name asked
about and the address in the answer.

```
ana@laptop:~$ dig +short www.example.com; dig +short nosuch.example.com
192.0.2.80
ana@laptop:~$ tshark -n -i eth0 -c 4 -f "udp port 53" -T fields -e dns.id -e dns.flags.response -e dns.flags.rcode -e dns.qry.name -e dns.a
Capturing on 'eth0'
4 packets captured
0x301b	False		www.example.com	
0x301b	True	0	www.example.com	192.0.2.80
0x26af	False		nosuch.example.com	
0x26af	True	3	nosuch.example.com	
```

`dig +short` printed one address for `www.example.com` and nothing at all for `nosuch.example.com`,
and an empty line is a poor way to learn why. The capture says it plainly.

**The transaction id pairs each response with its query.** `0x301b` asked about `www` and `0x301b`
answered, with reply code 0 and the address `192.0.2.80`. `0x26af` asked about `nosuch` and was
answered with reply code 3, which is NXDOMAIN, "no such name", and no address. UDP has no connection
to hold a question and its answer together, so the id does it, and the client throws away a response whose id matches no outstanding query.

For the whole of one response, `-O dns` prints the DNS layer in full. The same missing name was looked
up once more for this, so its id is new:

```
ana@laptop:~$ tshark -n -i eth0 -c 2 -f "udp port 53" -O dns 2>/dev/null | sed -n "/^Frame 2/,/Authority RRs/p"
Frame 2: 167 bytes on wire (1336 bits), 167 bytes captured (1336 bits) on interface eth0, id 0
Ethernet II, Src: 52:54:00:a8:0a:01, Dst: 52:54:00:a8:0a:14
Internet Protocol Version 4, Src: 192.0.2.53, Dst: 192.168.10.20
User Datagram Protocol, Src Port: 53, Dst Port: 38734
Domain Name System (response)
    Transaction ID: 0xbd0d
    Flags: 0x8583 Standard query response, No such name
        1... .... .... .... = Response: Message is a response
        .000 0... .... .... = Opcode: Standard query (0)
        .... .1.. .... .... = Authoritative: Server is an authority for domain
        .... ..0. .... .... = Truncated: Message is not truncated
        .... ...1 .... .... = Recursion desired: Do query recursively
        .... .... 1... .... = Recursion available: Server can do recursive queries
        .... .... .0.. .... = Z: reserved (0)
        .... .... ..0. .... = Answer authenticated: Answer/authority portion was not authenticated by the server
        .... .... ...0 .... = Non-authenticated data: Unacceptable
        .... .... .... 0011 = Reply code: No such name (3)
    Questions: 1
    Answer RRs: 0
    Authority RRs: 1
```

The flags field is sixteen bits and `tshark` lays them out one per line. **This response is
authoritative, `.1..`: it came from `ns`, the server that holds `example.com`**, not from a cache
repeating what somebody else said. The laptop asked for recursion and the server offers it. The last
four bits are the reply code, `0011`, 3, No such name. The answer section is empty and the authority
section holds one record, the zone's SOA, which tells resolvers how long they may remember that the
name does not exist; lesson 11's capture showed it as `SOA ns.example.com`.

At the top of the output, the IP source is `192.0.2.53`, the DNS server in the
data centre. The Ethernet source is `52:54:00:a8:0a:01`, which in this lab's scheme is the MAC of
`192.168.10.1`, the office router. **The IP addresses say who talked; the MAC addresses say only the
last hop**, and they are rewritten at every router on the way.
