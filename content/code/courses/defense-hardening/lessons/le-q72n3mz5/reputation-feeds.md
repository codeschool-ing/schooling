---
title: Lists somebody else keeps
version: 1
---

**Nobody at a ten-person firm can find dangerous domains by hand.** New ones are registered every
day, live for hours, and are gone before anybody would have written them down. So the names in a
real blocklist come mostly from **reputation feeds**: lists kept by organisations that watch
phishing, malware delivery and command-and-control traffic for a living, and publish what they find.

They come in a few shapes, and a resolver takes most of them:

| shape | what it is | how it reaches the resolver |
|---|---|---|
| an RPZ feed | a policy zone kept by somebody else | a zone transfer, `AXFR`/`IXFR`, from their server, refreshed on its own |
| a hosts-style list | one name per line, sometimes with `0.0.0.0` in front | a script that turns it into a zone file |
| a protective resolver | a public resolver that applies its own lists, such as Quad9 | the forwarder of your resolver points at it |
| a vendor service | a commercial product with categories and a console | the vendor's agent, or the resolver forwards to it |

abuse.ch's URLhaus publishes an RPZ of domains used to deliver malware; Spamhaus sells RPZ feeds
graded by category; Quad9 blocks what its partners report and answers everything else. **None of
them was used for this course**: the lab has no internet, and each one is described here from its
publisher's documentation. In Unbound, a feed transferred from another server is the same `rpz:`
block with `primary:` lines naming the server instead of a `zonefile:`; the lines you write are
nearly the same, and what changes is who decides what goes in them.

## The price of somebody else's list

A feed is somebody else's judgement about what is dangerous, applied to your users without asking
them. It will sooner or later list something your firm needs. Here the feed has decided that a
whole cloud provider's domain is dangerous, which happens when a provider hosts a few bad customers
among many good ones:

```
root@dns:~# echo "*.contabil-nuvem.example.net    CNAME ." >> /etc/unbound/feed.zone; systemctl restart unbound
ana@desk:~$ dig jatoba.contabil-nuvem.example.net | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 3939
```

`jatoba.contabil-nuvem.example.net` is where Jatobá keeps its accounting system. The line was
appended to the feed's file for the demonstration; in a real deployment it would have arrived with
the morning's transfer, and the first sign would be a phone call.

**The answer is an allowlist, kept by you, read before the feed.** A policy zone can say
`rpz-passthru.`, which means "answer this one truthfully", and Unbound applies policy zones in the
order the configuration lists them, stopping at the first that matches. So the allowlist is its own
zone, and its `rpz:` block goes first:

```
root@dns:~# cat > /etc/unbound/allow.zone <<'EOF'
$TTL 300
@ SOA localhost. hostmaster.jatoba.example. 1 3600 600 86400 300
@ NS localhost.
jatoba.contabil-nuvem.example.net  CNAME rpz-passthru.
EOF
root@dns:~# sed -i 's/^rpz:$/rpz:\n    name: allow.jatoba.example\n    zonefile: \/etc\/unbound\/allow.zone\n    rpz-log: yes\n    rpz-log-name: allow\nrpz:/' /etc/unbound/unbound.conf.d/jatoba.conf; sed -n '/^rpz:/,$p' /etc/unbound/unbound.conf.d/jatoba.conf
rpz:
    name: allow.jatoba.example
    zonefile: /etc/unbound/allow.zone
    rpz-log: yes
    rpz-log-name: allow
rpz:
    name: feed.jatoba.example
    zonefile: /etc/unbound/feed.zone
    rpz-log: yes
    rpz-log-name: feed
root@dns:~# unbound-checkconf && systemctl restart unbound; systemctl is-active unbound
unbound-checkconf: no errors in /etc/unbound/unbound.conf
active
ana@desk:~$ dig +short jatoba.contabil-nuvem.example.net; dig outro.contabil-nuvem.example.net | grep status
198.51.100.80
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 46161
root@dns:~# journalctl -u unbound -o cat | grep "rpz: applied" | tail -2 | cut -d" " -f3-
rpz: applied [allow] jatoba.contabil-nuvem.example.net. rpz-passthru 192.168.60.20@56887 jatoba.contabil-nuvem.example.net. A IN
rpz: applied [feed] *.contabil-nuvem.example.net. rpz-nxdomain 192.168.60.20@58254 outro.contabil-nuvem.example.net. A IN
```

The firm's own address answers again; the rest of the provider stays blocked, because nobody has
decided it should not be. And the log says which zone decided each time, `allow` for the first and
`feed` for the second. **An allowlist entry is a decision somebody owns**: it needs a reason, a
name beside it and a date to look at it again, because the domain allowed today may be the one
taken over next year.

Three habits keep a feed useful rather than a source of tickets:

- **Watch before you block.** Unbound can log what a zone would have done without doing it, with
  `rpz-action-override: disabled`; a week of that shows what a new feed would break.
- **Prefer narrow feeds to broad categories.** "Known malware delivery" is a short list with few
  mistakes; "newly registered domains" blocks thousands of legitimate sites a week.
- **Make the block visible.** The sinkhole's one-line page tells a person what happened and who to
  call. A silent `NXDOMAIN` looks like a broken internet.
