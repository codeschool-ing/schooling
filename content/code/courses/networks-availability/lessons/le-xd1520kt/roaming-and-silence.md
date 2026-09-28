---
title: A laptop behind NAT, and a key that is wrong
version: 1
---

`remote` is Ana's laptop at home, `192.168.1.50`, behind a home router, `homegw`, that translates it to
`198.51.100.77`. `hq`'s file has no `Endpoint` for her. Her own file, written when the lab was staged
and not printed here, names `hq` as `vpn.example.com:51820` and carries one extra line,
`PersistentKeepalive = 25`. She brings the tunnel up and pings the file server:

```
ana@remote:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=63 time=1.02 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.018/1.018/1.018/0.000 ms
ana@hq:~$ sudo wg show wg0 endpoints
FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE=	198.51.100.77:40817
n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=	198.51.100.2:51820
```

The ping works, and **`hq` now knows where she is: `198.51.100.77:40817`**, the home router's public
address and a port its NAT chose. Nobody typed that. `hq` learnt it from the first packet that
decrypted correctly under her key, and it keeps learning: every authenticated packet from a new address
moves the endpoint there.

That is roaming. A laptop that leaves the house for a hotel, or a phone that goes from Wi-Fi to mobile
data, sends its next packet from a new address, and `hq` answers at the new one. **There is no
reconnection, because the session was never tied to an address**, only to a key and the receiver index
from the handshake section. The lab did not move the laptop, so this is the mechanism rather than a
capture of it.

## Why the laptop sends packets with nothing in them

NAT has a catch. `homegw` keeps the mapping from port 40817 to `192.168.1.50` only while traffic uses
it, and a home router typically forgets an idle UDP mapping after a minute or two. WireGuard sends
nothing when it has nothing to send, so after a quiet spell a packet from `hq` to `198.51.100.77:40817`
would reach a door that is no longer there, and the office could not reach Ana until she sent something
first.

**`PersistentKeepalive = 25` makes the laptop send an empty authenticated packet every 25 seconds**,
enough to keep the mapping alive. Only the side behind NAT needs it. `hq` and `branch` have fixed public
addresses, and their files have no such line.

## The wrong key

For the next capture, `remote`'s file was given the wrong public key for `hq`: `branch`'s, a real key of
the lab and the wrong one. The ISP listened for her packets while she pinged:

```
ana@remote:~$ ping -c 7 -W 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.

--- 192.168.10.10 ping statistics ---
7 packets transmitted, 0 received, 100% packet loss, time 6124ms

ana@isp:~$ sudo tcpdump -n -ttt -i eth1 -c 2 udp port 51820 and host 198.51.100.77
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
 00:00:00.000000 IP 198.51.100.77.58867 > 203.0.113.2.51820: UDP, length 148
 00:00:05.277388 IP 198.51.100.77.58867 > 203.0.113.2.51820: UDP, length 148
2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@remote:~$ sudo wg show wg0 latest-handshakes
n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=	0
```

Seven pings over 6124 ms, all lost. On the wire in that time, **only two packets, both from Ana and
both 148 bytes: handshake initiations**, the same payload size as packet 1 of the handshake capture.
The second came 5.277388 seconds after the first, because an unanswered initiation is sent again about
every five seconds.

And `hq` sent nothing back. The initiation was built for the key Ana believed was `hq`'s. `hq` cannot
authenticate it with its own key, and **a WireGuard endpoint does not answer a packet it cannot
authenticate**, not even with an error. A port scanner gets exactly the silence it would get if nothing
were listening, which is a defence; it is also why this failure has to be diagnosed from one end.

`latest-handshakes` gives the diagnosis in one line. `0` means never, and the key it lists is
`n/CGaD63…`, which the `wg show` on `hq` said belongs to the branch. **The peer Ana is configured for is
not the machine at the other end.**

| what you see | where to look |
|---|---|
| initiations every ~5 s, no response, latest handshake `0` | the public key on one side, or UDP 51820 blocked on the way |
| a recent handshake, and some traffic still lost | `AllowedIPs` on the receiving side does not include the source |
| works, then goes quiet after an idle spell, from behind NAT | no `PersistentKeepalive` on the side behind NAT |
| large transfers hang, small ones pass | the MTU, lesson 21 |
