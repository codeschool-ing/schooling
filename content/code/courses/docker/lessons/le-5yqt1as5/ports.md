---
title: Publishing ports
version: 1
---

**A container has a network of its own, so a program listening inside it is listening on that
network, not on the machine's.** `shelf` listens on port 8080, and from Ana's shell there is nothing
there:

```
ana@vm:~$ docker run -d --name web shelf:1.0.0
c68c142ea23857936cfd9a03caef47b213c7f133ed577deeea2be5d589bf8b75
ana@vm:~$ curl -sS localhost:8080/version
curl: (7) Failed to connect to localhost port 8080 after 0 ms: Couldn't connect to server
ana@vm:~$ docker port web
```

`docker port` printed nothing because nothing was published. Lesson 4 showed the network namespace
that makes this so; lesson 23 opens it up properly. Here the question is narrower: how a request
from outside gets in.

## `-p host:container`

**`-p 8080:8080` asks Docker to listen on the host's port 8080 and pass every connection to the
container's port 8080.** The first number is the door on the machine, the second the program's own
port, and they need not match:

```
ana@vm:~$ docker run -d --name web -p 8080:8080 shelf:1.0.0
1dc693414105911a109d2d5113a9833d075161b231b05cd387367bd533df5772
ana@vm:~$ docker port web
8080/tcp -> 0.0.0.0:8080
ana@vm:~$ ss -ltn | grep -E "State|:8080"
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*          
ana@vm:~$ curl -s localhost:8080/version
1.0.0
```

**Read the address in `ss`: `0.0.0.0:8080`, every address the machine has.** That includes the
network card, so anyone who can reach Ana's machine can reach `shelf`. On a laptop on café Wi-Fi, or
a server with a public address, that is rarely what was meant.

There is a trap on Ubuntu in particular. **Docker writes its own firewall rules for published ports,
and they take effect before `ufw`'s**, so a port that `ufw status` lists as closed can still be open
to the world if a container published it. Docker's documentation has a page on exactly this. It was
not reproduced in the lab, which has no `ufw`; the defence does not depend on it either way.

## Publishing on one address

**Put an address in front: `-p 127.0.0.1:8080:8080` listens on the loopback address only**, which
only programs on the same machine can reach:

```
ana@vm:~$ docker run -d --name web -p 127.0.0.1:8080:8080 shelf:1.0.0
b9876626746a84d3fbf7f2aee8bd2cb62cd2ece1551adc133bfb588600dd880d
ana@vm:~$ ss -ltn | grep -E "State|:8080"
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      4096       127.0.0.1:8080       0.0.0.0:*          
ana@vm:~$ docker run -d --name web2 -p 127.0.0.1:8080:8080 shelf:1.0.0
447da7dba2602833cff15533977f60769db4e7cf6f4b1ac61f026fca0f48a44d
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web2 (14b39bd52054d41abdb9378217c7b985fd57aed370ad6f420c3cbc132bb2c74e): Bind for 127.0.0.1:8080 failed: port is already allocated

Run 'docker run --help' for more information
ana@vm:~$ docker run -d --name web3 -p 127.0.0.1:8081:8080 shelf:1.0.0
724e0656b59de95735161141b7cacad0df6915cf353cc1208960555282c667b0
ana@vm:~$ curl -s localhost:8081/version
1.0.0
```

`ss` now shows `127.0.0.1:8080`. **Make this the default for anything that is not meant to be
public**: a database, an admin page, a service that a proxy on the same machine forwards to.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Ana&#x27;s machine with two ways in: the loopback address 127.0.0.1, reachable only from the machine itself, and the network card, reachable from other machines. Inside, the container web runs shelf on its own port 8080, in its own network namespace. With -p 8080:8080 Docker listens on 0.0.0.0:8080, every address, so both Ana&#x27;s curl and another machine on the network reach shelf. With -p 127.0.0.1:8080:8080 it listens on the loopback address only, so Ana&#x27;s curl reaches shelf and the other machine does not. With no -p at all, nothing on the host leads to the container&#x27;s port.\"><defs><marker id=\"l17publish-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17publish-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170\" y=\"20\" width=\"530\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"186\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Ana's machine</text><rect x=\"186\" y=\"70\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"261\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">127.0.0.1</text><text x=\"261\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">loopback: this machine</text><rect x=\"186\" y=\"170\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"261\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">network card</text><text x=\"261\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reachable from outside</text><rect x=\"500\" y=\"100\" width=\"180\" height=\"96\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container web</text><text x=\"590\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf :8080</text><text x=\"590\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its own network</text><rect x=\"20\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">curl (Ana)</text><rect x=\"20\" y=\"178\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">another</text><text x=\"80\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">machine</text><path d=\"M140 110 L186 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17publish-ah-phosphor)\"></path><path d=\"M140 198 L186 198\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17publish-ah-amber)\"></path><path d=\"M336 98 L500 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l17publish-ah-phosphor)\"></path><path d=\"M336 198 L500 168\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l17publish-ah-amber)\"></path><text x=\"350\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">with either form of -p</text><text x=\"350\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">only with -p 8080:8080</text></svg>", "caption": "Publishing with -p opens a door on the host. The address before the ports says which side of the machine the door is on."}
```

The middle command is the other thing to know: **one host port, one container.** `web2` asked for
the door `web` already had and was refused, though Docker had already created the container, which
is why it printed an id before the error; `docker ps -a` would list it as `Created`. Two copies of
`shelf` need two host ports, and `web3` on 8081 works, with `shelf` inside still on its own 8080.
