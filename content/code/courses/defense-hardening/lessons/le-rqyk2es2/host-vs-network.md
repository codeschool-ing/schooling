---
title: A firewall on every machine
version: 1
---

**A network firewall decides what may cross between segments. A host firewall decides what may
reach, and leave, one machine.** The common picture puts all the filtering at the edge, between
the firm and the internet, and treats everything inside as trusted. Then one machine inside is
taken over, and the edge has nothing to say about what it does next, because everything it does
next happens inside.

Jatobá's lab shows the problem without anything going wrong. Every machine shares one segment,
and nothing on the segment filters anything:

```
ana@desk:~$ nc -zv -w2 web 22 2>&1; nc -zv -w2 web 80 2>&1
Connection to web (192.168.60.10) 22 port [tcp/ssh] succeeded!
Connection to web (192.168.60.10) 80 port [tcp/http] succeeded!
ana@web:~$ sudo -u portal nc -zv -w2 desk 22 2>&1
Connection to desk (192.168.60.20) 22 port [tcp/ssh] succeeded!
```

`desk` reaches SSH and the portal on `web`, which it may need. And `web`, under the portal's own
account, reaches SSH on `desk`, which the portal never needs. If the portal ever runs a command it
was not written to run, the way lesson 8 staged it, that is the first door it finds open: from one
machine to the next, which is called **lateral movement**, and it is how a single compromised
server becomes a compromised firm.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l10-lateral\" aria-label=\"Two machines on one segment. On web, two programs: nginx, run by the account www-data, and the portal, run by the account portal. From desk, connections to nginx on port 80 and to SSH on web are allowed. From web, the portal's attempt to open SSH on desk is refused by the per-account rule, and any new connection web starts towards desk is dropped by the outbound allow-list.\"><defs><marker id=\"l10-lateral-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-lateral-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"50.0\" width=\"230.0\" height=\"190.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"42.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"420.0\" y=\"50.0\" width=\"280.0\" height=\"190.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"432.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><rect x=\"470.0\" y=\"90.0\" width=\"200.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nginx</text><text x=\"570.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">account www-data</text><rect x=\"470.0\" y=\"170.0\" width=\"200.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">portal</text><text x=\"570.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">account portal</text><path d=\"M260.0 100.0 L470.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-lateral-dh-ah-phosphor)\"></path><text x=\"365.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">port 80, 22: allowed</text><path d=\"M470.0 190.0 L260.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-lateral-dh-ah-amber)\"></path><text x=\"365.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">portal to desk:22</text><text x=\"365.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">refused: rule per account</text><text x=\"365.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">anything web starts: dropped by its outbound allow-list</text><text x=\"360.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">the same segment, filtered on the host</text></svg>", "caption": "Nothing between the two machines filters anything. The rules live on web."}
```

A host firewall answers three questions a network firewall cannot:

- **Which program?** A network device sees addresses and ports. The machine itself knows which
  process owns each socket, which account runs it and which service started it, so a rule can say
  *the portal may not connect anywhere* and leave every other program alone.
- **What about the machine's neighbours?** Traffic between two machines on the same segment never
  crosses a network firewall at all. Only the two hosts see it.
- **What about when it leaves?** A laptop on a café's Wi-Fi is outside every network control the
  firm owns. Its own firewall is the only one it carries.

**The two do not replace each other.** The network firewall is one place to enforce a policy for
many machines, and the host firewall is the last word on each one. Lesson 5 already gave `web` an
inbound policy; this lesson is about the rules a network device could never write, per
application, and about the direction lesson 5 left open: **outbound**.

Start the lab with the machines this lesson uses:

```sh
sudo bash hostlab.sh up web desk
```
