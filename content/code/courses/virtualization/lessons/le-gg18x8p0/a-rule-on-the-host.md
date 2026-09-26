---
title: A rule on the host
version: 1
---

The doors are on the host, so that is where they are closed: a firewall rule for traffic that arrives
**from the lab's bridge**, `virbr2`, which labnet's description named on purpose. It is written for
nftables, the firewall built into Linux, in a file of its own:

```
ana@host:~$ cat labguard.nft
table inet labguard {
  chain input {
    type filter hook input priority 0; policy accept;
    iifname "virbr2" ct state established,related accept
    iifname "virbr2" udp dport { 53, 67 } counter accept
    iifname "virbr2" tcp dport 53 counter accept
    iifname "virbr2" counter drop
  }
}
ana@host:~$ sudo nft -f labguard.nft && sudo nft list tables
table ip filter
table ip nat
table ip mangle
table ip6 filter
table ip6 nat
table ip6 mangle
table inet labguard
```

Read from the top, and the first rule that matches decides:

- **`ct state established,related accept`**: replies to conversations the host started. Without it,
  the host's own ssh into the guests would break, because the answers come back through `virbr2`.
- **`udp dport { 53, 67 }`** and **`tcp dport 53`**: DHCP and DNS, which libvirt's network needs to give
  the guests their addresses.
- **`drop`**: everything else a guest starts towards the host, silently.

`table inet labguard` is a table of its own, so it can be removed in one command without touching the
rules libvirt keeps in the other tables. Then the same check, from the same guest:

```
ana@client:~$ bash check.sh 10.20.0.1
a route out of the lab: closed
the host's ssh: closed
the host's port 8000: closed
a shared folder: closed
a clipboard agent: closed
ana@client:~$ curl -sS -m 5 http://server/
lab server: ok
ana@client:~$ sudo networkctl renew enp1s0 && sleep 5 && ip -4 -br addr show enp1s0
enp1s0           UP             10.20.0.12/24 metric 100 
ana@host:~$ sudo nft list table inet labguard
table inet labguard {
        chain input {
                type filter hook input priority filter; policy accept;
                iifname "virbr2" ct state established,related accept
                iifname "virbr2" udp dport { 53, 67 } counter packets 81 bytes 5999 accept
                iifname "virbr2" tcp dport 53 counter packets 0 bytes 0 accept
                iifname "virbr2" counter packets 6 bytes 360 drop
        }
}
```

**Both doors into the host are closed**, the guests still reach each other, and the client asked for
its address again and still has it, `10.20.0.12`. Every `ana@client` line after the rule is also the host's
own ssh into the guest, still working. The counters say what happened: **81 DHCP and DNS packets
accepted and 6 dropped**, the knocks on ports 22 and 8000, sent more than once each because `nc`
repeats a request that gets no answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"What a lab guest can reach once the rule is in place. On the left, the office network, with the printer at 10.0.0.50; the host reaches it through lan0, 10.0.0.1, and the guests have no route to it. In the middle, the host, with three services: ssh on port 22, the notes server on port 8000, and DHCP and DNS. On the right, client at 10.20.0.12 and server, on labnet, where the host is virbr2, 10.20.0.1. From the guests, DHCP and DNS are accepted and ssh and port 8000 are dropped by labguard. The guests still reach each other.\"><defs><marker id=\"dr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the office network</text><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">printer</text><text x=\"180\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.0.50</text><rect x=\"250\" y=\"20\" width=\"230\" height=\"200\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host</text><rect x=\"262\" y=\"60\" width=\"206\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ssh, port 22</text><rect x=\"262\" y=\"104\" width=\"206\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">notes, port 8000</text><rect x=\"262\" y=\"148\" width=\"206\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">DHCP and DNS</text><text x=\"262\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lan0 10.0.0.1</text><text x=\"468\" y=\"208\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">virbr2 10.20.0.1</text><path d=\"M192 120 L248 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" marker-start=\"url(#dr-ah)\"></path><rect x=\"560\" y=\"50\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><text x=\"572\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.12</text><rect x=\"560\" y=\"150\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server</text><path d=\"M630 102 L630 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" marker-start=\"url(#dr-ah)\"></path><path d=\"M558 70 L472 76\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" stroke-dasharray=\"4 3\"></path><path d=\"M558 84 L472 120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" stroke-dasharray=\"4 3\"></path><path d=\"M558 170 L472 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\"></path><path d=\"M20 240 L56 240\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"64\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dropped by labguard</text><path d=\"M250 240 L286 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dr-ah)\"></path><text x=\"294\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">accepted</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no route from the guests</text></svg>", "caption": "The isolated network closes the way out; the rule closes the way into the host. What stays open is what the lab needs: addresses, names, and the guests reaching each other."}
```
