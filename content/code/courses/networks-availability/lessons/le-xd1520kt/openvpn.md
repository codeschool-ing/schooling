---
title: OpenVPN with its handshake hidden, and the two side by side
version: 1
---

Lesson 3 brought OpenVPN up and read its TLS handshake off the wire, Client Hello and all. Here it is
set up the way a remote-access server usually is, on `hq`, for Ana. The server's file, as `cat
/etc/openvpn/server.conf` printed it:

```schooling-example
{"language": "conf", "file": "server.conf", "parts": [{"code": "dev tun\nproto udp\nport 1194", "note": "A layer 3 tunnel, `tun`, over UDP on OpenVPN's registered port."}, {"code": "server 10.8.0.0 255.255.255.0\ntopology subnet", "note": "A pool for the clients. The server takes `10.8.0.1` and hands out the rest, one address per connection, all in one subnet."}, {"code": "ca ca.crt\ncert vpn-server.crt\nkey vpn-server.key", "note": "The authority both sides trust, and the server's own certificate and key. Each client has a certificate of its own from the same authority, and that is its identity."}, {"code": "dh none", "note": "No file of Diffie-Hellman parameters: the key exchange is done on elliptic curves instead."}, {"code": "tls-crypt tc.key", "note": "A key shared by the server and every client, which encrypts and authenticates the control channel, handshake included."}, {"code": "push \"route 192.168.10.0 255.255.255.0\"", "note": "Sent to each client as it connects: route the head office LAN into the tunnel, and nothing else. A split tunnel, which lesson 5 is about."}, {"code": "keepalive 10 60", "note": "A ping through the tunnel every 10 seconds, and a client restarts the connection after 60 without an answer. The server waits twice as long."}, {"code": "status /run/openvpn-status.log 5\nverb 3", "note": "Rewrite the list of who is connected into a file every 5 seconds, and log at the usual level."}]}
```

**Where WireGuard names a peer by a key written into the server's file, OpenVPN names a person by a
certificate the server has never seen before.** Any client whose certificate the lab's authority signed
can connect, and the server needs no line per user. That is the difference the rest of this section
keeps meeting.

`tls-crypt` needs a key of its own, generated once on the server and copied to every client, here to
Ana's laptop, as root and not shown:

```
ana@hq:~$ sudo head -3 /etc/openvpn/tc.key
#
# 2048 bit OpenVPN static key
#
```

It is not an identity, since every client holds the same file. **Its job is to make a packet without it
worthless before TLS starts.** The ISP captured the client connecting, with `tshark` started first and
the client started as root; then Ana pinged the file server through the tunnel:

```
ana@isp:~$ tshark -n -i eth1 -c 6 -f "udp port 1194"
Capturing on 'eth1'
6 packets captured
    1 0.000000000 198.51.100.77 → 203.0.113.2  OpenVPN 96 MessageType: P_CONTROL_HARD_RESET_CLIENT_V2
    2 0.000193540  203.0.113.2 → 198.51.100.77 OpenVPN 108 MessageType: P_CONTROL_HARD_RESET_SERVER_V2
    3 0.000432890 198.51.100.77 → 203.0.113.2  SSL 385 Continuation Data
    4 0.001937144  203.0.113.2 → 198.51.100.77 SSL 1248 Continuation Data
    5 0.001976314  203.0.113.2 → 198.51.100.77 SSL 1248 Continuation Data
    6 0.001991326  203.0.113.2 → 198.51.100.77 SSL 231 Continuation Data
ana@remote:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=63 time=0.859 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.859/0.859/0.859/0.000 ms
```

`tshark` still knows it is OpenVPN: the first two packets, the client's and the server's
`HARD_RESET`, carry their message type where it can read it. **After that there is no Client Hello, no
Server Hello, no version and no list of ciphers**, only `Continuation Data`, which is `tshark` finding
bytes where it expected TLS records it could parse. Lesson 3's capture, without `tls-crypt`, named every
step.

What an observer can no longer read matters less than what the server no longer does. A packet whose
`tls-crypt` authentication fails is dropped before OpenVPN's TLS code sees it, so **somebody without
`tc.key` cannot even begin a handshake**, which is the silence WireGuard gets from its keys, bought here
with one shared file. A client that leaves the company still has that file, which is why it protects
the door and the certificate still decides who comes in.

Ten seconds later the server's status file said who was connected:

```
ana@hq:~$ sudo cat /run/openvpn-status.log
OpenVPN CLIENT LIST
Updated,2026-09-28 18:09:09
Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since
ana,198.51.100.77:35979,3583,3611,2026-09-28 18:08:59
ROUTING TABLE
Virtual Address,Common Name,Real Address,Last Ref
10.8.0.2,ana,198.51.100.77:35979,2026-09-28 18:09:03
GLOBAL STATS
Max bcast/mcast queue length,0
END
ana@hq:~$ sudo grep -E "Peer Connection|primary virtual" /run/openvpn.log
2026-09-28 18:08:59 198.51.100.77:35979 [ana] Peer Connection Initiated with [AF_INET]198.51.100.77:35979
2026-09-28 18:08:59 ana/198.51.100.77:35979 MULTI: primary virtual IP for ana/198.51.100.77:35979: 10.8.0.2
```

**OpenVPN names the person.** `ana` is the Common Name in the certificate she connected with, beside the
real address it came from, `198.51.100.77:35979`, the home router again, and the tunnel address she got
from the pool, `10.8.0.2`. The log says the same with a time. Removing Ana means revoking her
certificate, with a revocation list the server checks (`crl-verify`, not configured here), and nobody
else's access changes. With WireGuard it means deleting her public key from `hq`'s file; the name *Ana*
was only ever a comment.

## The two side by side

| | WireGuard | OpenVPN |
|---|---|---|
| a peer is | a public key written into the other's file | a certificate signed by an authority |
| transport | UDP only | UDP, or TCP when a firewall insists (lesson 3) |
| cryptography | fixed by the protocol | negotiated by TLS |
| handshake | two packets, 190 and 134 bytes here | TLS inside OpenVPN's control channel |
| where it runs | the kernel (here `wireguard-go`, a fallback) | a program, `openvpn` |
| to a stranger without the key | no answer at all | no answer, with `tls-crypt` |
| tunnel addresses | written per peer | a pool, pushed with the routes |
| who is connected | keys and the latest handshake | names, in the status file |

**The choice follows who is at the other end.** Between routers the network team controls, a list of
keys is simpler than a certificate authority, and WireGuard's few lines are hard to get subtly wrong.
For people who join and leave, OpenVPN's certificates and names fit the job, and so does its TCP mode on
networks that block everything but web ports. Products built on WireGuard add the missing half, a
service that hands out keys per user; lesson 5 is about that difference between a site and a person.
