---
title: Detecting, and preventing
version: 1
---

**A host intrusion detection system notices; a host intrusion prevention system acts.** The two
names, HIDS and HIPS, describe the same kind of program at two settings of one dial. Both watch a
machine for signs that something is wrong. A HIDS writes an alert and leaves the decision to a
person. A HIPS makes the decision itself, at once: it refuses the login, blocks the address, stops
the program from opening the file.

The common picture is that prevention is simply better, because it does not wait for anybody.
**Prevention is better only where the rule is never wrong.** An alert that is wrong costs somebody
a minute. A block that is wrong locks out the director on the morning of the audit, and a HIPS that
does that twice is switched off by the third week. So every HIPS rule is chosen by asking how
certain it can be, and the ones that cannot be certain stay on the detection side of the dial.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-dial\" aria-label=\"One watch, two settings. On the left, detection: an event goes to a rule, the rule raises an alert, and a person decides. On the right, prevention: the same event and rule, and the program acts at once. Under them, a line from uncertain to certain: rules that can be wrong stay on the left, and only rules that are never wrong move to the right. fail2ban sits on the right; AIDE on the left.\"><defs><marker id=\"l11-dial-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"190.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">detection (HIDS)</text><rect x=\"40.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"85.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">event</text><path d=\"M130.0 63.0 L145.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"145.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"190.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rule</text><path d=\"M235.0 63.0 L250.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"295.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a person decides</text><text x=\"530.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">prevention (HIPS)</text><rect x=\"380.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"425.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">event</text><path d=\"M470.0 63.0 L485.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"485.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"530.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rule</text><path d=\"M575.0 63.0 L590.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"590.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"635.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the program acts</text><path d=\"M60.0 140.0 L660.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><text x=\"60.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the rule can be wrong</text><text x=\"660.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the rule is never wrong</text><circle cx=\"190.0\" cy=\"140.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"190.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AIDE</text><text x=\"190.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a file changed: was it right?</text><circle cx=\"560.0\" cy=\"140.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"560.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fail2ban</text><text x=\"560.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">three failures in ten minutes</text></svg>", "caption": "Prevention is detection trusted to act alone, and only certain rules earn that."}
```

This lesson puts one of each on `web`:

| | what it watches | what it does | how certain |
|---|---|---|---|
| **fail2ban** | the log of failed logins | blocks the address that keeps failing | very: a client that fails three times in ten minutes is either lost or guessing, and either way a short ban costs little |
| **AIDE** | the contents and permissions of chosen files | reports what changed since the last approved state | it is certain a file changed, and has no idea whether the change was right, so it only reports |

Lesson 8's EDR sits beside both. It watches behaviour, and its rules are where the dial is turned
with most care, which is why its response in that lesson was a person's decision.

A third kind of prevention works before anything happens at all: **mandatory access control**,
which confines a program to what it is allowed to touch, whatever it tries. It is the strongest of
the three and the one this lab cannot run, for a reason the section on it explains.

Start the lab with the machines this lesson uses:

```sh
sudo bash hostlab.sh up web desk
```
