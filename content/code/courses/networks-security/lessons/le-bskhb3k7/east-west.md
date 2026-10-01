---
title: East-west traffic, tested
version: 1
---

Traffic between clients and servers is **north-south**; traffic between servers is **east-west**, and it
is the direction an attacker moves in after the first foothold (lesson 9). With the generated rules on
both servers, every east-west cell is tested from its source:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  blocked
ana@db:~$ probe app:8080 app:22
app:8080               blocked
app:22                 blocked
```

`app` reaches the database and not `db`'s SSH; `db` reaches nothing on `app`. **Neither of these
connections crosses `fw`**: both machines sit on the servers segment, and before this lesson both were
open. Then the other roles:

```
ana@www:~$ probe app:8080 db:5432
app:8080               open
db:5432                blocked
ana@admin:~$ probe app:22 db:22 db:5432
app:22                 open
db:22                  open
db:5432                blocked
```

The proxy reaches the application and not the database. The admin role reaches SSH on both servers
and not the database port.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The servers segment after microsegmentation. app and db share one switch, and each has its own firewall around it. From www, the proxy, only port 8080 on app is open. From app, only port 5432 on db. From admin, only SSH on each. db opens nothing towards app, and nothing else inside the segment is open.\"><defs><marker id=\"ms-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"ms-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"230\" y=\"20\" width=\"470\" height=\"190\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"238\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">servers segment</text><rect x=\"250\" y=\"50\" width=\"180\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"265\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"275\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:8080  :22</text><rect x=\"500\" y=\"50\" width=\"180\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"515\" y=\"70\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"525\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"525\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:5432  :22</text><path d=\"M430 93 L500 93\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-phosphor)\"></path><text x=\"465\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">:5432</text><rect x=\"20\" y=\"60\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"30\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">proxy role</text><path d=\"M140 85 L250 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-phosphor)\"></path><text x=\"200\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">:8080</text><rect x=\"20\" y=\"160\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"30\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">admin role</text><path d=\"M140 175 L340 175 L340 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-paper-dim)\"></path><path d=\"M340 175 L590 175 L590 140\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ms-ah-paper-dim)\"></path><text x=\"360\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:22 on each, from admin only</text></svg>", "caption": "One switch, two machines, and a separate wall around each."}
```

The result is the matrix of lesson 4, drawn again at the level of single machines, **enforced where the
traffic actually is**. A compromised `app` can now reach one port on one other machine, the one the
application needs, and nothing else on its own segment.

Two practical notes. The generated files are **replaced whole** on every run, which is why they start
with `flush ruleset`: a host's rules are the policy's output, never edited by hand on the host, or the
next generation silently removes the edit. And the policy file is the thing to review and version, as
lesson 5 asked of the firewall's: a change to who may reach the database is a one-line diff somebody can
approve.
