---
title: Two connections, and which way they go
version: 1
---

Every `ls` and every `put` printed a `229` first. FTP carries commands on one connection, to port 21,
and every listing and every file on **a second connection, opened for that transfer and closed after
it**. `229 Entering Extended Passive Mode (|||40007|)` is the server saying which port to connect to
for the next one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"An FTP session in passive mode. The laptop opens a control connection to www on port 21 and sends commands over it: USER, PASS, EPSV, LIST, QUIT. To EPSV the server replies 229, naming a port, 40006 in this example. The laptop then opens a second connection, the data connection, to that port, and the listing or the file travels over it; it closes when the transfer is done. The control connection stays open for the whole session.\"><defs><marker id=\"tc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"110\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"32\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"590\" y=\"30\" width=\"110\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"602\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><path d=\"M130 76 L588 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tc-ah)\"></path><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">control connection, to port 21</text><text x=\"360\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">USER, PASS, EPSV, LIST, QUIT</text><path d=\"M588 124 L132 124\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tc-ah)\"></path><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">229 Entering Extended Passive Mode (|||40006|)</text><path d=\"M130 170 L588 170\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tc-ah)\"></path><text x=\"360\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">data connection, to the port the server named</text><text x=\"360\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the listing, or the file, and then it closes</text></svg>", "caption": "Two connections for one session: commands on 21, and a new data connection for every listing and every file. Both are opened by the client, which is what passive means."}
```

That is **passive** mode: the client opens both connections. FTP is older than NAT and firewalls, and
its original **active** mode works the other way round: the client says where it is listening, and the
server connects back to it. curl can be told to do that:

```
ana@laptop:~$ curl -sS -v --ftp-port - -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^[<>] (PORT|EPRT|5)|curl:"
> EPRT |1|192.168.10.20|38787|
< 500 Illegal EPRT command.
> PORT 192,168,10,20,177,245
< 500 Illegal PORT command.
curl: (30) Failed to do PORT
ana@laptop:~$ curl -sS -v -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^[<>] (EPSV|229)|Connecting|^-rw"
> EPSV
< 229 Entering Extended Passive Mode (|||40000|)
* Connecting to 192.0.2.80 (192.0.2.80) port 40000
-rw-r--r--    1 1001     1001          109 Sep 25 18:26 index.html
```

`EPRT` and `PORT` both tell the server `192.168.10.20`, the laptop's own address, which is private
(lesson 2). The router rewrote the packets' source to `203.0.113.2` on the way out, but not the address
written inside the command. The server saw a command from one address asking it to connect to another,
and refused it: `500 Illegal PORT command`. Even if it had tried, nothing on the internet reaches
`192.168.10.20`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Active mode behind NAT. The laptop, at 192.168.10.20, sends PORT with its own address, asking the server to connect back to it. The office router rewrites the packets&#x27; source address to 203.0.113.2, but not the address written inside the command. The server, www, sees a command from 203.0.113.2 naming 192.168.10.20, a private address it could not reach anyway, and answers 500 Illegal PORT command.\"><defs><marker id=\"an-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"32\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"300\" y=\"60\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">router</text><text x=\"312\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"580\" y=\"60\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"592\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><path d=\"M140 72 L298 72\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><path d=\"M420 72 L578 72\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an-ah)\"></path><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PORT 192.168.10.20,…</text><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">connect back to me here</text><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NAT rewrites the source address</text><path d=\"M578 100 L422 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an-ah)\" stroke-dasharray=\"5 4\"></path><text x=\"700\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">500 Illegal PORT command</text><text x=\"700\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the command came from 203.0.113.2 and names another address</text></svg>", "caption": "In active mode the server connects back to the client, and behind NAT the client does not know its own public address. The router rewrote the packet and not the words inside it."}
```

The second command is curl's default, passive: `EPSV`, a port in the reply, and a connection the laptop
opens itself, which NAT handles like any other. **Behind NAT, FTP works in passive mode or not at
all.**
