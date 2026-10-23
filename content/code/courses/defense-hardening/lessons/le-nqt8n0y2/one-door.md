---
title: One door for administrators
version: 1
---

**The path an administrator uses to reach a server is the most valuable path on the network.** It
ends at root on that server. Every other path in this course leads to one service, one account, one
file; this one leads to the whole machine, and from there to whatever that machine trusts. So it gets
the most careful treatment, and the first part of that treatment is to have **one** of them.

Start the lab for this lesson:

```sh
sudo bash hostlab.sh up admin jump web desk
```

As the lab comes up, every machine can open SSH to every other one, because every machine has your
key. Ask `web` from a workstation and from the administrator's machine:

```
ana@desk:~$ ssh web hostname
web
ana@admin:~$ ssh web hostname
web
ana@admin:~$ ssh jump hostname
jump
```

All three work. That is the state of most small networks, and it means the question "who could have
logged in to `web` last night" has as many answers as there are machines. If `desk` is the machine
somebody's phishing link ran on, then `desk` is a way to `web`, with the key it already holds.

## The shape of the fix

A **jump server**, or bastion, is a machine whose only job is to be the way in. Administrators reach
it from their own workstation; it reaches the servers; the servers accept administrative connections
from it and from nothing else. Three properties follow, and each one is something you can check:

| property | what it buys |
|---|---|
| servers accept SSH only from the jump server | a stolen key is useless from any other machine |
| the jump server does nothing else | no web browser, no mail, nothing that fetches content from strangers, so it is hard to get a foothold on |
| every administrative session crosses one machine | one place to log, to require a second factor, and to cut off |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l15-one-door\" aria-label=\"Two drawings of administrative access. On the left, before: admin, desk and a laptop each have a line straight to web and to db, six paths in all. On the right, after: admin has one line to jump, and jump has one line to each server; desk and the laptop have no line to any server.\"><defs><marker id=\"l15-one-door-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-one-door-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">before: every machine is a way in</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">after: one door</text><rect x=\"20.0\" y=\"50.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">admin</text><rect x=\"20.0\" y=\"120.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"20.0\" y=\"190.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">laptop</text><rect x=\"230.0\" y=\"80.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><rect x=\"230.0\" y=\"170.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">db</text><path d=\"M120.0 68.0 L230.0 98.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 68.0 L230.0 188.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 138.0 L230.0 98.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 138.0 L230.0 188.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 208.0 L230.0 98.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 208.0 L230.0 188.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><rect x=\"390.0\" y=\"50.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">admin</text><rect x=\"390.0\" y=\"120.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"390.0\" y=\"190.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">laptop</text><rect x=\"520.0\" y=\"50.0\" width=\"80.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">jump</text><rect x=\"620.0\" y=\"120.0\" width=\"80.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M580.0 86.0 L640.0 120.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-phosphor)\"></path><rect x=\"620.0\" y=\"190.0\" width=\"80.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">db</text><path d=\"M580.0 86.0 L640.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-phosphor)\"></path><path d=\"M490.0 68.0 L520.0 68.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-phosphor)\"></path><text x=\"460.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">desk and the laptop reach no server</text></svg>", "caption": "Six paths to audit before, one after. The servers decide which, not the administrators."}
```

A jump server is only as strong as the rules that force traffic through it. **A bastion that
servers do not insist on is a convenience, not a control**: administrators use it on good days and
go round it on the day it matters. The rest of the lesson builds the door, then closes the other
ways round it, then makes the keys that open it expire, and finally makes it say who came through.
