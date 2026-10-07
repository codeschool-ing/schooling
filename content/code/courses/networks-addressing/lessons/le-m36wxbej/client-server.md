---
title: The one that waits and the one that asks
version: 2
---

The usual picture of a server is a machine: a big box in a rack, more powerful than a desk PC. **A
server is a role a program takes, and the role is to wait.** It opens a port, tells the operating
system it will accept connections there, and does nothing until somebody arrives. A client is the
program that arrives: it knows the server's address and port in advance, and it starts the
conversation.

In lesson 1's office, built with `sudo bash ~/netlab/netlab.sh up office`, `srv` is a namespace on the same computer as every PC, with the same
kind of virtual card. What makes it a server is one program, a small web server that `office.sh` starts on it.
`ss -tln` lists the TCP sockets that are listening (`-t` for TCP, `-l` for listening, `-n` for numbers
instead of names):

```
root@srv:~# ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5        10.20.10.10:80        0.0.0.0:*          
```

One line, in state `LISTEN`, on `10.20.10.10:80`. The peer column says `0.0.0.0:*`: nobody is on the
other end yet, and any address with any port may become the other end. (`Send-Q` on a listening
socket is its backlog, how many finished connections may queue before the program accepts them, and
this server asked for 5.) From pc1, a client asks:

```
ana@pc1:~$ curl -s http://srv/
served by srv
```

`curl` did what every client does. It looked up the name `srv`, which the lab wrote into pc1's
`/etc/hosts`, connected to port 80, sent a request, and printed what the server wrote back: `served
by srv`.

**One listener serves many clients at once.** Three PCs connect and keep their connections open, each
with `sleep 4 | timeout 6 nc -N srv 80`, because a web page's own connection closes in milliseconds and
would never be caught. Meanwhile the server lists its TCP connections with `ss -tn`, which leaves the listener out:

```
root@srv:~# ss -tn
State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
ESTAB 0      0        10.20.10.10:80    10.20.10.23:52730       
ESTAB 0      0        10.20.10.10:80    10.20.10.21:60504       
ESTAB 0      0        10.20.10.10:80    10.20.10.22:59648       
```

Three lines, all `ESTAB` (established), all with the same local side, `10.20.10.10:80`. The peer side
is what differs: `10.20.10.23:52730`, `10.20.10.21:60504` and `10.20.10.22:59648`. The server did not
open a new port for each client. The listening socket stays where it was, and each connection it
accepts becomes a socket of its own, told apart from the others by who is at the far end.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"Three clients and one server, from the office lab. On the left, pc1 at 10.20.10.21 port 60504, pc2 at 10.20.10.22 port 59648 and pc3 at 10.20.10.23 port 52730, each with a port its own kernel picked. Each has an arrow to the one box on the right, srv at 10.20.10.10 port 80: one listening socket, three connections.\"><defs><marker id=\"fan-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">clients: an ephemeral port each</text><text x=\"470\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">server: one known port</text><rect x=\"20\" y=\"34\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.21:60504</text><path d=\"M220 58 C 340 58, 360 98, 466 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fan-ah)\"></path><rect x=\"20\" y=\"100\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"32\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.22:59648</text><path d=\"M220 124 C 340 124, 360 120, 466 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fan-ah)\"></path><rect x=\"20\" y=\"166\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"32\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.23:52730</text><path d=\"M220 190 C 340 190, 360 142, 466 142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fan-ah)\"></path><rect x=\"470\" y=\"76\" width=\"230\" height=\"88\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"484\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"484\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">10.20.10.10:80</text><text x=\"484\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one listening socket</text><text x=\"484\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">three connections</text></svg>", "caption": "The three connections srv listed. The server side is the same on all three; what tells them apart is the client's address and port."}
```

That is what makes client-server simple to run. The server's address and port are published once —
in a DNS record, a configuration file, a URL — and every client finds it the same way. It is also the
model's weakness: when `srv` stops, all three conversations stop with it, and no client can do
anything about that. The last section of this lesson weighs the two sides.
