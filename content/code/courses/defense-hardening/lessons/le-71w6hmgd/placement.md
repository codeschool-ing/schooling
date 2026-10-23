---
title: Where bait goes, and where it never goes
version: 1
---

**Bait works where an intruder walks and nowhere else.** A honeypot in a corner of the network
nobody explores never fires, and one that fires all day because it sits on a busy path teaches the
firm to ignore it. The question for each piece is the same: after the first machine falls, where
does somebody look next?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-placement\" aria-label=\"Where bait goes on a network like Jatobá's. The internet is outside the firm's firewall and holds no bait. Inside, among the servers beside web, a decoy server. Among the workstations beside desk, bait ports on an idle machine. Inside web itself, a honeytoken in a backup directory. Arrows show the path an intruder takes: from a workstation to the servers, and into the files of the server they reach.\"><defs><marker id=\"l13-placement-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"120.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"80.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">internet</text><text x=\"80.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no bait here</text><path d=\"M150.0 40.0 L150.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"158.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">firewall</text><rect x=\"180.0\" y=\"40.0\" width=\"230.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">workstations</text><rect x=\"200.0\" y=\"80.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">desk</text><rect x=\"300.0\" y=\"150.0\" width=\"95.0\" height=\"44.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"347.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">idle machine,</text><text x=\"347.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">bait ports</text><rect x=\"450.0\" y=\"40.0\" width=\"250.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"465.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">servers</text><rect x=\"470.0\" y=\"80.0\" width=\"100.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">web</text><rect x=\"480.0\" y=\"108.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">honeytoken</text><rect x=\"590.0\" y=\"80.0\" width=\"95.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"637.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">decoy server</text><text x=\"637.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">trap</text><path d=\"M290.0 98.0 L470.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-placement-dh-ah-paper-dim)\"></path><text x=\"352.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">intruder looks around</text><path d=\"M570.0 120.0 L590.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-placement-dh-ah-paper-dim)\"></path></svg>", "caption": "Bait sits on the path from the first machine to the next, and inside what they reach."}
```

On a network like Jatobá's that gives three places:

- **Among the servers.** A machine like `trap`, named and dressed like the others, beside `web` and
  the database. Somebody on `web` who lists the network sees one more server worth trying.
- **Among the workstations.** Bait ports on an otherwise idle workstation, or a share that looks
  like the finance department's. Most intrusions start on a workstation and spread from there.
- **Inside the machines themselves.** Honeytokens where the real secrets would be: a credentials
  file in a backup directory, a key in a home directory, a password in a script. These fire after
  the network bait, when somebody is already in.

## Where it never goes

**A honeypot is never exposed to the internet by a firm that wants to detect intrusions.** On the
internet it would be scanned and touched thousands of times a day by automated tools, which tells
the firm nothing about its own network and fills the alert channel with noise. Research honeypots
on the internet exist, run by people whose job is to study that noise, on networks kept well away
from anything they protect.

**And bait never weakens what it sits beside.** A honeypot that offered a real login with a weak
password would be a way in with an alarm on it, which is still a way in. That is the main reason to
prefer low interaction: `bait.py` accepts a connection and closes it, and there is nothing behind
it to break into. The bait file holds credentials for an account that does not exist, never a real
one disabled for the occasion. A honeypot machine gets the same hardening as every other, lesson 1
included, and is itself isolated by the firewall rules of lesson 10, so that even a successful
attack on it leads nowhere.

## Who reads the alert

Bait that fires into a log nobody reads is decoration. Each honeypot alert goes to wherever the
firm's other alerts go, with one difference: **it is never batched or summarised.** A honeypot alert
is rare by design, so the one that arrives deserves a person within minutes, not a line in a weekly
report.
