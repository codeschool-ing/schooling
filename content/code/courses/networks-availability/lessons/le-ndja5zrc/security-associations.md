---
title: Security associations, and what the ISP still sees
version: 1
---

What IKE produced can be listed on `hq`. This ran a few seconds after the trapped ping of the last
section:

```
ana@hq:~$ sudo swanctl --list-sas
offices: #1, ESTABLISHED, IKEv2, a765344132816bcb_i* e1e4340708b3cac9_r
  local  'hq.example.com' @ 203.0.113.2[500]
  remote 'branch.example.com' @ 198.51.100.2[500]
  AES_CBC-256/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/MODP_2048
  established 3s ago, rekeying in 13907s
  lans: #2, reqid 1, INSTALLED, TUNNEL, ESP:AES_GCM_16-256
    installed 3s ago, rekeying in 3288s, expires in 3957s
    in  7fdf3ac6,    168 bytes,     2 packets,     1s ago
    out 41b696e1,    168 bytes,     2 packets,     1s ago
    local  192.168.10.0/24
    remote 192.168.20.0/24
```

**A security association is one direction of protected traffic, so a tunnel is two of them.** Under
`lans`, `in 7fdf3ac6` is what `branch` sends to `hq`, and `out 41b696e1` is the reverse. Each is an SPI,
Security Parameter Index, 32 bits chosen by the side that receives with it. Both counters say
`168 bytes, 2 packets`: the two pings that got through, **84 bytes each, counted before encryption.**

Above them is the IKE SA. Its two SPIs are marked `_i` and `_r`, initiator and responder, and the `*`
marks this side's, so `hq` started it. The CHILD SA uses `ESP:AES_GCM_16-256`. GCM encrypts and computes
a 16-byte ICV in one pass, which is why the proposal names no separate integrity algorithm.

The CHILD SA was installed 3 seconds before the listing, so `rekeying in 3288s, expires in 3957s` means
3291 and 3960 seconds after installation. **Rekeying makes new keys while the old ones still work**, and
traffic never waits for a negotiation after the first. The expiry, 3600 × 1.1, is a hard limit reached
only if rekeying fails. The rekey comes before 3600 because strongSwan subtracts a random amount, so two
peers do not both renegotiate at the same instant.

## On the wire

The ISP's router, while the laptop sent one more ping:

```
ana@isp:~$ sudo tcpdump -n -t -v -i eth0 -c 2 esp
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP (tos 0x0, ttl 64, id 342, offset 0, flags [DF], proto ESP (50), length 140)
    203.0.113.2 > 198.51.100.2: ESP(spi=0x41b696e1,seq=0x3), length 120
IP (tos 0x0, ttl 63, id 38130, offset 0, flags [DF], proto ESP (50), length 140)
    198.51.100.2 > 203.0.113.2: ESP(spi=0x7fdf3ac6,seq=0x3), length 120
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**`spi=0x41b696e1` is `hq`'s `out` SA, and the reply carries `0x7fdf3ac6`, its `in`.** The SPI tells
`branch` which key to use before it has decrypted anything. `seq=0x3` follows the two pings counted
above.

The 84-byte ping is 140 bytes on the wire: **56 bytes of IPsec, against 20 for IP-in-IP** in lesson 1.
Twenty are the new IP header. `length 120` is ESP's share, and its 36 bytes of overhead split as the
figure in the first section draws them. The padding depends on the length of what is inside, so **ESP's
overhead is not one fixed number**, and lesson 1's MTU arithmetic needs a margin.

## Nothing readable

Lesson 1 read a GRE tunnel with `tcpdump -A`. The same test against ESP counts the lines containing `GET`
or `served` in ten packets, while the till fetched the page; it fetched it again for the transcript:

```
ana@isp:~$ sudo tcpdump -l -n -t -A -i eth0 -c 10 esp | grep -c -E "GET|served"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10 packets captured
10 packets received by filter
0 packets dropped by kernel
0
ana@till:~$ curl -s http://192.168.10.10/
served by files
```

**Zero.** The page crossed the ISP's router inside those packets, and not one printable line of it was
there. The ISP still knows which offices talked, when, how often and how much: **encryption hides the
contents of a conversation, not the fact that it happened.**
