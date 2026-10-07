---
title: Hashing the source address, and why five clients are too few
version: 1
---

Some applications need every request from one client to reach the same server, a problem the next
section takes up properly. The oldest way to get that without reading the request is **to hash the
client's address: the same address always produces the same number, so it always picks the same
server**. HAProxy calls it `balance source`, and it works for any TCP service, not only HTTP. Five
machines of the lab each send four requests:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance source
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
ana@laptop:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@remote:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@till:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@isp:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web1
served by web1
served by web1
served by web1
ana@ns:~$ for i in $(seq 4); do curl -s http://www.example.com/; done
served by web2
served by web2
served by web2
served by web2
```

Every client stayed on one server, which is what was asked. But **four of the five landed on `web1`, one
on `web2` and none at all on `web3`**. Nothing is broken. A hash spreads addresses evenly only when there
are many of them, in the way that a coin comes up heads about half the time over a thousand throws and
can easily come up heads four times in five. With five clients, a third of the servers doing nothing is
an ordinary result.

The lab also shows the second reason a source hash balances badly in real life. `lb1` does not see
`192.168.10.20`, the laptop's own address: it sees the address the connection arrives from, which for the
laptop is `hq`'s public `203.0.113.2`, after the office's NAT, covered in `networks-addressing`. Every
machine in the head office arrives from that one address, so **a whole office behind NAT is one client to
a source hash**, and it all goes to one server. A mobile operator's carrier-grade NAT does the same to
thousands of phones at once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" aria-label=\"Five clients and the address lb1 sees for each: laptop, 192.168.10.20, is seen as 203.0.113.2 after NAT at hq; remote, 192.168.1.50, as 198.51.100.77 after NAT at homegw; till, 192.168.20.30, as 198.51.100.2 after NAT at branch; isp as 192.0.2.1 and ns as 192.0.2.53, with no NAT. The hash sends the first four to web1 and ns to web2. web3 gets none.\"><defs><marker id=\"h19-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">client</text><text x=\"250\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the address lb1 sees</text><text x=\"560\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">server chosen by the hash</text><rect x=\"20\" y=\"30\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"95.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><path d=\"M170 50 L248 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"34\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">203.0.113.2</text><text x=\"390\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">NAT at hq</text><path d=\"M480 50 C 520 50, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"80\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remote</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.1.50</text><path d=\"M170 100 L248 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"84\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">198.51.100.77</text><text x=\"390\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">NAT at homegw</text><path d=\"M480 100 C 520 100, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">till</text><text x=\"95.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M170 150 L248 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"134\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">198.51.100.2</text><text x=\"390\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">NAT at branch</text><path d=\"M480 150 C 520 150, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"180\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"95.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.1</text><path d=\"M170 200 L248 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"184\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.0.2.1</text><text x=\"390\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no NAT</text><path d=\"M480 200 C 520 200, 530 90, 578 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"20\" y=\"230\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ns</text><text x=\"95.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.0.2.53</text><path d=\"M170 250 L248 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"250\" y=\"234\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.0.2.53</text><text x=\"390\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no NAT</text><path d=\"M480 250 C 520 250, 530 170, 578 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#h19-ah)\"></path><rect x=\"580\" y=\"70\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web1</text><text x=\"655\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 clients</text><rect x=\"580\" y=\"150\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web2</text><text x=\"655\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 client</text><rect x=\"580\" y=\"230\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web3</text><text x=\"655\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">none</text></svg>", "caption": "The source-hash run, with the addresses the balancer actually hashes: for three of the five, a NAT address rather than the machine's own. Every machine in the head office would arrive as 203.0.113.2."}
```

The hash has one more weakness. HAProxy divides the hash by the servers' total weight and keeps the
remainder, so adding or removing a server changes the divisor, and most clients move to a different
server at once. `hash-type consistent` is HAProxy's way of moving only the clients that have to, and it
was not run here.

A source hash earns its place for protocols the balancer cannot read, and inside a network where every
client has an address of its own. **For HTTP from the internet, persistence belongs in the request**,
which is where a cookie is.
