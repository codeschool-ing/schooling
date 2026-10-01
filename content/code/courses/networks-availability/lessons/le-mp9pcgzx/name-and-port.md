---
title: A name, a port, a page
version: 1
---

## The name

With the gateway fixed, the next fault arrives by name:

```
ana@laptop:~$ curl -sS -m 10 http://www.example.com/
curl: (6) Could not resolve host: www.example.com
```

Error 6 this time, `Could not resolve host`. **curl never tried to connect**, because it had no address
to connect to. The question is whether the laptop cannot reach its DNS server or is asking the wrong one,
and divide and conquer answers it with the server's address:

```
ana@laptop:~$ ping -c 1 192.0.2.53
PING 192.0.2.53 (192.0.2.53) 56(84) bytes of data.
64 bytes from 192.0.2.53: icmp_seq=1 ttl=62 time=0.337 ms

--- 192.0.2.53 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.337/0.337/0.337/0.000 ms
ana@laptop:~$ dig +time=2 +tries=1 www.example.com | grep -E "timed out|status"
;; communications error to 192.0.2.54#53: timed out
ana@laptop:~$ dig @192.0.2.53 +short www.example.com
192.0.2.80
ana@laptop:~$ cat /etc/resolv.conf
nameserver 192.0.2.54
```

The lab's DNS server, `ns` at `192.0.2.53`, answers a ping. A plain `dig`, which asks whatever server the
laptop is configured with, **reports who it asked**: `192.0.2.54`, which never replied. The same question
put to `192.0.2.53` with `@` gets `192.0.2.80`, the right answer. So the network is fine and DNS is
fine, and the laptop is asking an address where nothing listens. `/etc/resolv.conf` says so in one line.
The fix is that line, or whatever writes it on that machine: a DHCP lease, NetworkManager,
systemd-resolved.

The `grep` for `status` printed nothing, and that is information too. A server that answers, even to say
a name does not exist, produces a status line; **no status line means no answer at all**.

## The port

```
ana@laptop:~$ curl -sS http://192.0.2.21/
curl: (7) Failed to connect to 192.0.2.21 port 80 after 0 ms: Couldn't connect to server
ana@laptop:~$ ping -c 1 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.073 ms

--- 192.0.2.21 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.073/0.073/0.073/0.000 ms
```

The same words as the gateway fault, `Couldn't connect to server`, **after 0 ms instead of 3057**. A
connection refused at once means a machine received the SYN and answered it with a reset, which is what
TCP does for a port where nothing listens. A firewall set to reject rather than drop does the same, so
the ping, which proves the machine is up, is not the end of it. The next question goes to web1 itself:

```
ana@web1:~$ ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      4096         0.0.0.0:5201      0.0.0.0:*          
ana@web1:~$ ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*          
LISTEN 0      4096         0.0.0.0:5201      0.0.0.0:*          
```

The first listing has one listener, on port 5201, the `iperf3` server lesson 22 uses, and **nothing on
80**: nginx had stopped. The second listing was taken after it was started again, off screen, and
`0.0.0.0:80` is back. **A layer 4 question is settled on the server, not the client.** `ss -tln` lists
what listens, and it takes a second.

## The page

```
ana@laptop:~$ curl -sS -o /dev/null -w "%{http_code}\n" http://192.0.2.21/reports/
404
```

**A 404 is a network success.** A name resolved, a route delivered, a port accepted the connection, and a
program read the request and answered it. Every test a network tool can make has passed. What is left is
a URL that does not exist, a page that moved, or a server configured to look in the wrong directory, and
those are questions for whoever runs the application, with its log open. Telling them "the network is
fine, web1 answered 404 for `/reports/`" saves the hour they would otherwise spend proving it.

Five answers so far, by what the client said:

| what the client said | after | layer | what settled it |
|---|---|---|---|
| nothing: no reply and no error | — | 1 and 2 | `ip -br link`, `ethtool` |
| `Couldn't connect to server` | 3057 ms | 3 | `ip route`, `ip neigh` |
| `Could not resolve host` | — | DNS | `dig`, then `dig @192.0.2.53` |
| `Couldn't connect to server` | 0 ms | 4 | `ss -tln` on the server |
| `404` | — | 7 | the application's own log |
