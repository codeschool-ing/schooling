---
title: Four failures, four messages
version: 1
---

The model earns its keep when something breaks, because **each layer fails with its own message**.
The laptop was broken four times, once per layer, and each message is worth recognising on sight.

Layer 1 and 2, the link. Taking the interface down is what an unplugged cable looks like to the
system:

```
ana@laptop:~$ sudo ip link set eth0 down
ana@laptop:~$ ping -c 2 192.0.2.80
ping: connect: Network is unreachable
ana@laptop:~$ ip -br link show eth0
eth0@if107       DOWN           52:54:00:a8:0a:14 <BROADCAST,MULTICAST> 
```

`Network is unreachable` came back immediately, without a packet being sent: with no link there is no
route, and the system knows it has nowhere to send anything. `LOWER_UP` is gone from the flags.

Layer 2 and 3, the neighbour. `192.168.10.99` is inside the office's `/24`, so the laptop tries ARP,
and nobody answers:

```
ana@laptop:~$ ping -c 2 192.168.10.99
PING 192.168.10.99 (192.168.10.99) 56(84) bytes of data.
From 192.168.10.20 icmp_seq=1 Destination Host Unreachable
From 192.168.10.20 icmp_seq=2 Destination Host Unreachable

--- 192.168.10.99 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1014ms
pipe 2
```

`Destination Host Unreachable` **from the laptop's own address**, `192.168.10.20`: the laptop is
reporting that its own ARP question went unanswered. The machine is off, unplugged, or does not
exist.

Layer 4, the port. The route works and the server is up, but nothing listens on 8080:

```
ana@laptop:~$ curl -sS http://www.example.com:8080/
curl: (7) Failed to connect to www.example.com port 8080 after 6 ms: Couldn't connect to server
```

Layer 7, the name. A typo, `ww` for `www`:

```
ana@laptop:~$ curl -sS https://ww.example.com/
curl: (6) Could not resolve host: ww.example.com
```

Nothing was sent to any web server at all: the name never became an address. And one more, where
**every layer worked** and the answer was still no:

```
ana@laptop:~$ curl -sI https://www.example.com/prices
HTTP/2 404 
server: nginx/1.24.0 (Ubuntu)
date: Fri, 25 Sep 2026 16:06:01 GMT
content-type: text/html
content-length: 162
```

| message | layer | what to look at |
|---|---|---|
| `Network is unreachable` | 1 to 3, this machine | the cable, the Wi-Fi, the address, the route |
| `Destination Host Unreachable` from yourself | 2 and 3, the link | the other machine is off or not there |
| `Connection refused` | 4, the other machine | the service is not running, or on another port |
| a timeout, no answer | 3 or 4, in between | a firewall, lesson 3 |
| `Could not resolve host` | 7, DNS | the name, or the DNS server, lesson 4 |
| `404`, `500` and other HTTP codes | 7, the application | the site itself: the network is fine |

**The last row is the one that saves the most time.** An HTTP error means the whole path worked, and
no amount of restarting the router will fix a page that does not exist.
