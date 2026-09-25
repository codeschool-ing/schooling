---
title: Changing a record, and "propagation"
version: 1
---

The website is moving to a new server, `192.0.2.81`. On `ns1`, the zone file gets the new address,
and its **serial number** goes up by one, which is how secondary servers know the zone changed:

```
ana@ns1:~$ grep -E "^www|SOA" /etc/bind/db.example.com
@            SOA    ns1.example.com. hostmaster.example.com. 2026092501 3600 900 1209600 300
www    300   A      192.0.2.80
www    300   AAAA   2001:db8:10::80
ana@ns1:~$ sudo sed -i 's/2026092501/2026092502/; s/^www    300   A      192.0.2.80/www    300   A      192.0.2.81/' /etc/bind/db.example.com
ana@ns1:~$ sudo named-checkzone example.com /etc/bind/db.example.com
zone example.com/IN: loaded serial 2026092502
OK
ana@laptop:~$ dig @ns1.example.com +noall +answer www.example.com
www.example.com.        300     IN      A       192.0.2.81
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        293     IN      A       192.0.2.80
```

**`named-checkzone` before reloading**, every time: a typo in a zone file can take the whole domain
off the internet, and the check costs a second. Then `ns1` was told to reload, and the two questions
at the end tell the story. `ns1` answers **`192.0.2.81`** at once. The resolver still answers
**`192.0.2.80`**, with 293 seconds to go: it asked before the change, and it was told it could keep the
answer for 300 seconds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"A timeline of the address change, read off the TTLs the resolver gave. The resolver answers 192.0.2.80 with a TTL of 299. Five seconds later, 192.0.2.80 with 294. Then ns1 is changed to 192.0.2.81. Asked again, the resolver still answers .80, with 293 seconds left. After its cache is flushed, it answers .81 with a fresh TTL of 300. Without the flush it would have kept answering .80 until the TTL reached zero, 300 seconds after it cached the record.\"><defs><marker id=\"tl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 70 L690 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tl-ah)\"></path><text x=\"650\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><circle cx=\"40\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"34\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">answer .80, TTL 299</text><circle cx=\"180\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"174\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">again: .80, TTL 294</text><circle cx=\"320\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"314\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ns1 changed to .81</text><circle cx=\"450\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"444\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resolver: .80, TTL 293</text><circle cx=\"580\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"574\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">flushed: .81, TTL 300</text><rect x=\"40\" y=\"118\" width=\"640\" height=\"26\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"52\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">without the flush: .80 until the TTL reached zero, 300 seconds after it was cached</text></svg>", "caption": "What gets called propagation is caches expiring. Every resolver that asked before the change keeps the old answer for as long as the TTL it was given."}
```

**That is all "DNS propagation" is**: every resolver in the world that asked before the change keeps
the old answer until its TTL runs out. Nothing is being sent anywhere. The resolver's operator can cut
it short:

```
ana@resolver:~$ sudo unbound-control -c /etc/unbound/unbound.conf flush www.example.com
ok
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        300     IN      A       192.0.2.81
```

Nobody can flush every resolver in the world, though, which is why a move is planned around the TTL.
**Lower it days before the change**, to 300 seconds or less, wait for the old, longer TTL to run out,
make the change, and raise the TTL again afterwards. Then "propagation" takes minutes. With a TTL of a
day, which is common, it takes a day, and there is nothing anybody can do about it on the morning of
the move.
