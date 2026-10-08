---
title: Half-open connections and SYN cookies
version: 1
---

A TCP connection starts with three packets: the client's `SYN`, the server's `SYN-ACK`, the client's
`ACK`. Between the second and the third, the server holds a **half-open connection** in memory,
waiting. A client that sends `SYN`s and never finishes, usually from source addresses that are not
its own, fills that memory, and real clients are turned away. That is a **SYN flood**, the classic
protocol attack.

The defence is built into Linux, and it is on by default. In your lab this lesson starts from
`sudo bash nslab.sh reset`, with the company's policy loaded on `fw` by `nft -f baseline.nft`. On `www`:

```
root@www:~# sysctl net.ipv4.tcp_syncookies net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_synack_retries
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 5
```

The queue of half-open connections holds 1,024, and a `SYN-ACK` is resent 5 times before the server
gives up. `tcp_syncookies = 1` is what matters: **when the queue fills, the server stops keeping
half-open connections at all**. It encodes what it would have remembered into the sequence number of
its `SYN-ACK`, a *cookie*, and forgets the connection. A real client's `ACK` carries that number back,
the server checks it and builds the connection then. A flood of `SYN`s that never finish now costs
the server nothing to remember.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two timelines of a TCP handshake between a client and a server. Without SYN cookies, the server keeps a half-open entry from the SYN until the client&#x27;s ACK arrives. With SYN cookies and a full queue, the server keeps nothing: it writes what it would have remembered into the sequence number of its SYN-ACK, and rebuilds the connection when the ACK brings that number back.\"><defs><marker id=\"sc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sc-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">without cookies</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><text x=\"270\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server</text><path d=\"M50 50 L50 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M250 50 L250 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M50 70 L250 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"130\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN</text><path d=\"M250 115 L50 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"130\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN-ACK</text><path d=\"M50 160 L250 185\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"140\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ACK</text><text x=\"260\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">holds a half-open entry</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">with cookies, queue full</text><text x=\"390\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><text x=\"630\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">server</text><path d=\"M410 50 L410 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M610 50 L610 200\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></path><path d=\"M410 70 L610 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"490\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN</text><path d=\"M610 115 L410 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"490\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SYN-ACK</text><path d=\"M410 160 L610 185\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sc-ah-paper-dim)\"></path><text x=\"500\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ACK</text><text x=\"620\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">holds nothing</text><rect x=\"252\" y=\"95\" width=\"8\" height=\"90\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"620\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">seq = cookie</text></svg>", "caption": "A SYN that never finishes costs the server a queue slot, or, with a cookie, nothing."}
```

## The firewall has the same problem

`fw` tracks every connection that crosses it, including the ones that never complete, so a SYN flood
through it fills the conntrack table of lesson 1. Its timeouts decide how long a half-open entry lives:

```
root@fw:~# sysctl net.netfilter.nf_conntrack_tcp_timeout_syn_sent net.netfilter.nf_conntrack_tcp_timeout_syn_recv net.netfilter.nf_conntrack_tcp_timeout_established
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 120
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 60
net.netfilter.nf_conntrack_tcp_timeout_established = 432000
```

A connection that saw only a `SYN` is kept for 120 seconds; one that saw the `SYN-ACK` for 60. Next to
the five days of an established connection, those look small, but a flood is measured in thousands of
packets a second, and every second of timeout is thousands of entries. Shortening the ones that belong
to unfinished handshakes costs nothing to legitimate clients, which finish in milliseconds:

```
root@fw:~# sysctl -w net.netfilter.nf_conntrack_tcp_timeout_syn_recv=20
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 20
```

A change with `sysctl -w` lasts until the next restart. The permanent version goes in a file under
`/etc/sysctl.d/`, where it is also documented for the next person.
