---
title: Workstations have no business with each other
version: 1
---

Once software runs on one laptop, it looks for the next machine. On a flat staff LAN it finds every
other computer answering on the ports Windows uses to share files, **445**, and to offer remote
desktop, **3389**. On `desk`, both answer to anybody on the segment:

```
ana@laptop:~$ probe desk:445 desk:3389
desk:445               open
desk:3389              open
```

Lesson 4 already noticed that the firewall never sees this traffic, because both machines are on the
same segment. **Workstations rarely need to talk to each other**: files live on servers, printing goes
through a print server, support connects from the management segment. So the rule is the same as
everywhere else in this course, applied on the machine itself: allow what is used, drop the rest.

`desk` gets a host firewall:

```
root@desk:~# cat host.nft
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    icmp type echo-request limit rate 5/second accept
    ip saddr 192.168.99.0/24 tcp dport { 22, 3389 } accept comment "support works from the management segment"
  }
}
root@desk:~# nft -f host.nft
```

Policy `drop` on input. Replies and loopback pass, ping is answered at a limited rate, and remote
desktop and SSH are allowed **only from the management segment**, where support works. File sharing is
not allowed at all, because a workstation should not be serving files. From `laptop`, both doors are
now closed:

```
ana@laptop:~$ probe desk:445 desk:3389
desk:445               blocked
desk:3389              blocked
```

And `desk` itself still works normally, because its own outgoing connections come back as
`established`:

```
ana@desk:~$ curl -s https://www.example.com/
orders service: ok
```

**This is the single most effective network control against ransomware spreading**, and it costs
nothing but the discipline of doing it on every workstation, which is what central management of
host firewalls is for. The Windows equivalent is its built-in firewall, set by group policy to refuse
inbound file sharing and remote desktop from the LAN. Lesson 21 generalises the idea to every server.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The staff LAN with its host firewalls. laptop&#x27;s attempts to reach desk on port 445, file sharing, and port 3389, remote desktop, are dropped by desk&#x27;s own firewall. admin, on the management segment, reaches desk on 3389 through fw, which desk&#x27;s firewall allows. desk&#x27;s own connections out to the shop still work.\"><defs><marker id=\"lt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"lt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"lt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"30\" width=\"420\" height=\"110\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"18\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">staff LAN</text><rect x=\"30\" y=\"70\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"40\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"260\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">desk</text><text x=\"270\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">host firewall: drop</text><path d=\"M170 85 L255 85\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#lt-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"176\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:445  :3389</text><text x=\"176\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">dropped at desk</text><rect x=\"560\" y=\"70\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"570\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">management</text><path d=\"M560 100 L410 105\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#lt-ah-phosphor)\"></path><text x=\"470\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">:3389</text><text x=\"455\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">allowed from mgmt</text><rect x=\"260\" y=\"166\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"270\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the shop, in the DMZ</text><path d=\"M335 116 L335 166\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#lt-ah-paper-dim)\"></path><text x=\"326\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desk&#x27;s own traffic, out</text></svg>", "caption": "Neighbours on a segment no longer trust each other; support still gets in, from where support works."}
```
