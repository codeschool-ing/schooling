---
title: Scoping: the edges, and the evidence for them
version: 1
---

**Scope** is the answer to "what does this incident include?": which accounts, which hosts, which data, which
outside parties. It sets the work of every later phase, because you contain, eradicate and recover what is
in scope. Scoping is iterative: start from what you know, ask what each item touched, and stop when the
answers stop growing.

From the address, which accounts did it use?

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT DISTINCT user FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success'"
user 
-----
bruno
```

From that account, which hosts did it reach that night?

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT host, src_ip, count(*) AS logins FROM logs WHERE user = 'bruno' AND action = 'success' AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30' GROUP BY host, src_ip"
host   src_ip         logins
-----  -------------  ------
files  198.51.100.22  1     
gw     203.0.113.66   2     
```

From those hosts, what left?

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT dst_ip, dst_port, count(*) AS n FROM logs WHERE src_ip = '192.168.20.10' AND product = 'firewall' AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30' GROUP BY 1, 2"
dst_ip         dst_port  n
-------------  --------  -
203.0.113.200  443       1
```

The chain closes: one address, one account, two hosts, one outside destination. Drawn, with the other half:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The scope of Thursday's incident as a path: the outside address 203.0.113.66 reached gw as bruno; from gw, bruno's account reached files; files sent data to 203.0.113.200. These four are in scope. Below, what was checked and found outside the scope: the other four staff accounts, and every other destination files sent to, which was only the backup provider.\"><rect x=\"10\" y=\"20\" width=\"700\" height=\"96\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"20\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">in scope</text><rect x=\"30\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">203.0.113.66</text><text x=\"105.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outside</text><rect x=\"200\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">gw</text><text x=\"275.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bruno, password, then key</text><rect x=\"380\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">files</text><text x=\"455.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bruno, from gw</text><rect x=\"550\" y=\"46\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">203.0.113.200</text><text x=\"625.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">612 MB received</text><path d=\"M180 74 L200 74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M200 74 L192.0 70.0 L192.0 78.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M350 74 L370 74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M370 74 L362.0 70.0 L362.0 78.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 74 L550 74\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 74 L542.0 70.0 L542.0 78.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked, and out of scope</text><rect x=\"20\" y=\"152\" width=\"320\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ana, carla, diego, helena</text><text x=\"180.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no login from 203.0.113.66</text><rect x=\"380\" y=\"152\" width=\"320\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">other destinations from files</text><text x=\"540.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only the backup, 203.0.113.150</text></svg>", "caption": "In scope, and checked and out. Scope is a claim with evidence on both sides of the line."}
```

The bottom row is the half most scoping leaves out. **"Out of scope" is also a claim**, and it needs its own
evidence: the other four accounts had no login from the address, and `files` sent nothing that night except
to the backup and to `203.0.113.200`. Write both down, with the queries that showed them, because the first
question from management will be "could it be more?", and "we checked these, here is how" is a different
answer from "we don't think so".

Scope also has a **data** dimension that logs answer badly. The flow says 612 MB left; it does not say which
612 MB. Which client files were on `files`, and which of them could the account read, is a question for the
file server's owner, and the answer decides lesson 21.
