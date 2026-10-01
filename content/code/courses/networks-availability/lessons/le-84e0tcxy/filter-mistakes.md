---
title: When a filter surprises you
version: 1
---

The commonest mistake is also the only one that is caught: a capture filter typed where a display
filter was expected.

```
ana@mon:~$ tshark -r files.pcap -Y "port 80"
tshark: "80" was unexpected in this context.
    port 80
         ^~
  Note: That read filter code looks like a valid capture filter;
        maybe you mixed them up?
```

`port 80` is valid BPF and means nothing to the display filter, which wants a field:
`tcp.port == 80`. **The error names the likely cause itself**, and in the window the bar turns red
before Enter is pressed, so this one costs seconds.

The second produces no error at all. Every IP packet carries two addresses, `ip.src` and `ip.dst`,
and `ip.addr` matches either of them. So what should `ip.addr != 192.0.2.21` mean: that some address
in the packet differs, or that no address equals it? The two readings select very different packets,
and the file was asked both ways:

```
ana@mon:~$ tshark -r files.pcap -Y "ip.addr != 192.0.2.21" | wc -l
18
ana@mon:~$ tshark -r files.pcap -Y "!(ip.addr == 192.0.2.21)" | wc -l
18
```

**In the version recorded here the two gave the same 18 packets**, so `!=` means "no address
equals", exactly `!(ip.addr == 192.0.2.21)`. The number checks out: the file held 45 packets, and
the conversation statistics in the next section count 27 of them to or from `192.0.2.21`. Older
Wireshark releases read `!=` the other way, as "some address differs", which is true of nearly
every packet, because a packet to `192.0.2.21` has a source that is something else. Guides from that
era tell you to type `!(ip.addr == …)`, and **that form means the same in every version**, so it is
the one worth keeping in your fingers.

Two more, both of which matched:

```
ana@mon:~$ tshark -r files.pcap -Y "dns.qry.name == www.example.com" | head -n 2
   11 0.008987287 192.168.10.10 → 192.0.2.53   DNS 98 Standard query 0x9ce1 A www.example.com OPT
   12 0.009225585   192.0.2.53 → 192.168.10.10 DNS 130 Standard query response 0x9ce1 A www.example.com A 192.0.2.80 OPT
ana@mon:~$ tshark -r files.pcap -Y "http.request.uri contains \"nothing\""
   39 1.105093152 192.168.10.10 → 192.0.2.23   HTTP 151 GET /nothing-here HTTP/1.1 
```

A name compared with `==` has to match whole, and it found the query in frame 11 and its response
in frame 12. **`contains` looks for a piece of a field**, and found the request for `/nothing-here`
by one word of its path. The backslashes belong to the shell: the whole filter sits in double quotes
for `bash`, so the quotes around the string inside it are escaped. In the window, with no shell in
between, it is typed as `http.request.uri contains "nothing"`.

A capture filter goes wrong more quietly still, because a valid filter that selects nothing records
nothing, and an empty capture reads exactly like "the traffic never happened". The laptop's capture
in the first section was a correct filter in the wrong place, and it caught one ARP request. **Before
concluding that something was not sent, check that the capture could have seen it**: the right
interface, the right port of the switch, and a filter tried once on traffic you know is there.
