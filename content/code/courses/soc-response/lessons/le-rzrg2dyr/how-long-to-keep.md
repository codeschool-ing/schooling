---
title: How long to keep a log
version: 1
---

The question sounds technical and is not. **How long a log is kept is decided by three things**: what
the law and contracts require at least, what an investigation needs, and what privacy law allows at most.
The disk is the last constraint, and lesson 1 measured how cheap the small sources are.

**The floor comes from law and contracts.** In Brazil, the **Marco Civil da Internet** (Law 12.965/2014)
sets two: a connection provider keeps connection records for **one year** (art. 13), and an application
provider that operates as a business keeps access records to its applications for **six months**
(art. 15). The **PCI DSS** standard, which binds anybody who handles payment cards, asks for **twelve
months** of audit logs, the most recent three of them immediately available. A sector regulator, a client
contract or an insurance policy can add its own.

**The need comes from how late problems are found.** A compromise discovered in March that began in
November is invisible in a log kept for sixty days, and the question "when did it start" goes unanswered.
Investigations reach back weeks or months, so the useful period is longer than most first guesses.

**The ceiling comes from privacy law.** A log full of addresses and account names is personal data. The
**LGPD** fixes no number for logs, but its principle of **necessity** (art. 6) and the duty to eliminate
data once its purpose ends (art. 16) mean that keeping everything for ever is a decision somebody has to
justify. A retention policy states both ends, and the reason for each.

The usual answer is two tiers, drawn here for a company that is an application provider and also takes
card payments:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A retention plan drawn as two bands along a time axis of thirteen months. Hot: the first three months, searchable in the SIEM. Warm: months 4 to 13, compressed files that can be loaded back. Deleted after that. Two legal floors are marked: six months for an application provider under the Marco Civil da Internet, and twelve months for PCI DSS.\"><rect x=\"30\" y=\"60\" width=\"152.3076923076923\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"106.15384615384615\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hot</text><text x=\"106.15384615384615\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">searchable</text><rect x=\"182.3076923076923\" y=\"60\" width=\"507.6923076923077\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"436.15384615384613\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">warm: compressed, restorable</text><text x=\"436.15384615384613\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read only when asked for</text><path d=\"M30 130 L690 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M30.0 126 L30.0 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"30.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M182.3076923076923 126 L182.3076923076923 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"182.3076923076923\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M334.6153846153846 126 L334.6153846153846 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"334.6153846153846\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M639.2307692307692 126 L639.2307692307692 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"639.2307692307692\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><path d=\"M690.0 126 L690.0 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"690\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">months</text><path d=\"M334.6153846153846 40 L334.6153846153846 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"334.6153846153846\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Marco Civil, art. 15: 6 months</text><path d=\"M639.2307692307692 106 L639.2307692307692 186\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"633.2307692307692\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">PCI DSS: 12 months</text><text x=\"690\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">then deleted</text></svg>", "caption": "A plan has a floor set by law and contracts, and a ceiling set by the principle of necessity."}
```

**Hot** storage is the SIEM itself: fast to search, expensive per gigabyte, three months. **Warm**
storage is compressed files on cheaper disks or in an object store: slow to load back, but there.
Whatever passes the ceiling is deleted, and the deletion is itself logged. Write down, per source, which
tier it lives in and for how long; a policy that says "logs are kept for one year" without saying which
logs is a policy nobody can check.
