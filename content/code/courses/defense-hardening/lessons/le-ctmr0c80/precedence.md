---
title: When two policies disagree
version: 1
---

**Several GPOs reach most machines, and some of them set the same thing differently.** The domain's
baseline says the screen locks after fifteen minutes; the reception OU's policy says five. Which
one the machine applies is not a matter of opinion: Group Policy processes the GPOs in a fixed order
and, where two set the same setting, **the one processed last wins.** As in the last section, this
is Microsoft's documented behaviour and none of it was run for this course.

## The order: local, site, domain, organisational unit

The order is remembered as **LSDOU**:

1. the **local** policy stored on the machine itself;
2. GPOs linked to the **site**;
3. GPOs linked to the **domain**;
4. GPOs linked to each **OU**, from the top of the tree down to the OU the machine is in.

Because later wins, the most specific container wins: an OU's policy overrides the domain's, and a
child OU's overrides its parent's. The local policy, processed first, loses to everything; it
matters only on a machine that is not in a domain. Within one container, GPOs are processed by
**link order**, and the GPO with link order 1 is processed last and so wins over the others linked
there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-lsdou\" aria-label=\"Group Policy processing order for one computer in the OU Reception, inside the OU Jatoba, inside the domain. Step 1, the local policy, sets the screen lock to 30 minutes. Step 2, the site, sets nothing. Step 3, the domain baseline, sets 15 minutes. Step 4a, the OU Jatoba, sets nothing. Step 4b, the OU Reception, sets 5 minutes. Each later step overwrites the one before, so the computer locks after 5 minutes, the value of the last and most specific container.\"><defs><marker id=\"l03-lsdou-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l03-lsdou-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"80.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">local policy</text><text x=\"80.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lock after 30 min</text><path d=\"M140.0 105.0 L160.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"160.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"220.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">site</text><text x=\"220.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(nothing set)</text><path d=\"M280.0 105.0 L300.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">domain baseline</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lock after 15 min</text><path d=\"M420.0 105.0 L440.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4a</text><text x=\"500.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">OU Jatoba</text><text x=\"500.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(nothing set)</text><path d=\"M560.0 105.0 L580.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4b</text><text x=\"640.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">OU Reception</text><text x=\"640.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">lock after 5 min</text><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">processed in this order; a later setting overwrites an earlier one</text><rect x=\"470.0\" y=\"190.0\" width=\"230.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the reception computer</text><text x=\"585.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">locks after 5 minutes</text><path d=\"M640.0 150.0 L620.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-phosphor)\"></path><text x=\"20.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Enforced on the domain link would make step 3 win over 4a and 4b</text></svg>", "caption": "Local, site, domain, OU: the last one processed wins, and it is the most specific."}
```

## The two switches that change the order

**Enforced**, set on a link, makes that GPO's settings win over any GPO linked lower in the tree,
even where a lower one sets the same thing. It is how a security team makes sure the baseline
linked at the domain cannot be loosened by an OU administrator.

**Block inheritance**, set on an OU, stops GPOs linked above it from applying to it, so the OU starts
from its own policies alone. It does not stop an Enforced link: Enforced was made to survive exactly
this.

Used together they describe a hierarchy of who may decide what: the domain sets the rules nobody
below may relax, and enforces them; each OU decides the rest. A blocked OU with no enforced baseline
above it is a part of the fleet the security team no longer governs, and it is found by reading
`gpresult` on a machine in it, not by reading the GPOs one by one.

## Loopback, for machines that belong to their job

User Configuration follows the person, wherever they log on. On a shared machine, a reception desk
or a meeting-room computer, that is backwards: the machine's job should decide. **Loopback
processing**, enabled on the computer's GPO, applies the User Configuration of the GPOs that reach
the *computer*. In **Replace** mode the user's own policies are ignored; in **Merge** mode both
apply and the computer's win on a conflict.

## What to take to Linux

The same three questions apply to any central configuration: in what order are the sources read,
which one wins a conflict, and what can override the order. The next section asks them of Ansible,
where the answers are written in a precedence table rather than in a tree.
