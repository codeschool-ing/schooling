---
title: Implementation groups
version: 1
---

153 safeguards are too many for a nine-person shop to do at once, and many of them would be wasted
effort there. So the CIS Controls sort every safeguard into **implementation groups (IGs)**, by the kind
of organisation that needs it:

```schooling-figure
{"svg": "<svg id=\"sf-implementation-groups\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The CIS implementation groups as nested sets. IG1, essential cyber hygiene, 56 safeguards, inside IG2, 130 safeguards, inside IG3, all 153. The shop sits in IG1.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"172\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">IG3 · 153 safeguards</text><text x=\"36\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">security specialists, serious public impact</text><rect x=\"60\" y=\"66\" width=\"520\" height=\"108\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">IG2 · 130 safeguards</text><text x=\"76\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dedicated IT staff, more sensitive data</text><rect x=\"100\" y=\"116\" width=\"320\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"116\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">IG1 · 56 safeguards</text><text x=\"116\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">essential cyber hygiene: the shop</text></svg>", "caption": "Each group contains the one before it. IG1 is the floor for everybody."}
```

| group | for whom | safeguards (cumulative) |
|---|---|---|
| **IG1** | small and medium organisations with limited IT and security expertise, holding mostly ordinary business data | **56** |
| **IG2** | organisations with dedicated IT staff, several departments, more sensitive data or regulatory duties | **130**: IG1 plus 74 |
| **IG3** | organisations with security specialists, holding data or running services whose compromise would be serious for the public | **153**: IG2 plus 23 |

**IG1 is described as essential cyber hygiene**: the minimum every organisation should do, whatever its
size. The groups are cumulative, so an IG2 organisation does everything in IG1 and more.

### The shop is IG1

A small online bookshop with one IT person and ordinary customer data is the textbook IG1 case. That is
good news: 56 safeguards is a list ana can work through. A few examples of what IG1 contains, and where
the shop already is:

| safeguard area in IG1 | the shop |
|---|---|
| an inventory of enterprise assets | partly: lesson 2's asset list, not yet complete |
| secure configuration process | the next section's checklist is the start of one |
| disable accounts that are not used | the leavers process of lesson 6 |
| MFA for externally exposed applications and remote access | the portal's next step, lesson 9 |
| automated backups, protected, with an isolated copy | lesson 12 |
| security awareness training | not yet |
| an incident response process: who to call, how to report | not yet |

The last two "not yet" rows are the honest output of the exercise. A short IG1 list, gone through line by
line, produces the shop's to-do list in an afternoon.

### Not a ranking of organisations

The groups describe what an organisation **needs**, not how good it is. An IG1 organisation that does
all 56 safeguards well is in a far better position than an IG3 one that claims all 153 and does half.
Moving up a group is a decision driven by risk, as everything in this course is: the shop moves toward
IG2 when it starts holding more sensitive data or hiring more IT staff, not because a higher group sounds
better.
