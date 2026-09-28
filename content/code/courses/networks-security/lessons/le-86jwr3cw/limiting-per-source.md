---
title: Limiting what one source may hold
version: 1
---

Lesson 3's proxy limited how fast one client may **ask**. The firewall can limit how much one client
may **hold**: how many connections it has open at once. A client with a hundred open connections to
the shop is either very unusual or not a customer.

nftables counts connections per source with a **dynamic set**: a set the rules fill as traffic
arrives, one element per client, each carrying a count of that client's open connections:

```
root@fw:~# cat perclient.nft
table ip filter {
  set web_clients {
    type ipv4_addr
    flags dynamic
    size 65535
  }
  chain forward {
    iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter reject with tcp reset comment "at most 4 open connections per client"
  }
}
```

`add @web_clients { ip saddr ct count over 4 }` adds the source to the set, or finds it there, and
matches when that source already has **more than four** tracked connections. A matching packet is
answered with a TCP reset, so the client learns at once rather than waiting. The rule has to come
before the rule that accepts the internet into the shop, or the accept would decide first:

```
root@fw:~# nft list chain ip filter forward | sed -n "3,5p"
		type filter hook forward priority filter; policy drop;
		ct state established,related accept
		iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter packets 0 bytes 0 reject with tcp reset comment "at most 4 open connections per client"
```

Then `remote` opens six connections and keeps them all open:

```
ana@remote:~$ for i in 1 2 3 4 5 6; do exec {fd}<>/dev/tcp/www.example.com/443 && echo "connection $i: open" || echo "connection $i: refused"; done; sleep 1
connection 1: open
connection 2: open
connection 3: open
connection 4: open
bash: connect: Connection refused
bash: line 1: /dev/tcp/www.example.com/443: Connection refused
connection 5: refused
bash: connect: Connection refused
bash: line 1: /dev/tcp/www.example.com/443: Connection refused
connection 6: refused
```

**Four open, then refused.** The limit counts per source, so another client on the internet is not
affected, and the counter shows the two refusals:

```
ana@branch:~$ exec {fd}<>/dev/tcp/www.example.com/443 && echo "branch: open"
branch: open
root@fw:~# nft list chain ip filter forward | grep "at most 4"
		iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter packets 2 bytes 120 reject with tcp reset comment "at most 4 open connections per client"
```

When `remote`'s connections close, its count drops and it is served again:

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
```

## Setting the number

Four is a demonstration. A real limit is set from what real clients do: a browser opens up to six
connections to one host, and a whole office behind one NAT address shares one count, the problem
lesson 3 met with rate limits. Measure the busiest legitimate source first, then set the limit well
above it.

**A limit per source does nothing against a distributed attack**, where each of ten thousand sources
stays politely under it. It is the right tool for one noisy client and one component of a DDoS
defence, never the whole of one.
