---
title: The four treatments
version: 1
---

Once a risk is ranked, something has to be decided about it. There are exactly four options, and
every security decision you will ever see is one of them, or a mix:

```schooling-figure
{"svg": "<svg id=\"sf-treatments\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The four treatments of a risk. Mitigate: put in a control that lowers likelihood or impact. Transfer: move consequences to somebody else by contract, such as insurance; accountability stays. Avoid: stop the activity that creates the risk. Accept: live with it, written, signed and dated.\"><defs><marker id=\"sf-treatments-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"270\" y=\"14\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a ranked risk</text><path d=\"M360 48 L100 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"20\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">mitigate</text><rect x=\"20\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">add a control</text><text x=\"100\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lower likelihood or impact</text><path d=\"M360 48 L275 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"195\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">transfer</text><rect x=\"195\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">insurance, a contract</text><text x=\"275\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">accountability stays</text><path d=\"M360 48 L450 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"370\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">avoid</text><rect x=\"370\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stop the activity</text><text x=\"450\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the risk goes to zero</text><path d=\"M360 48 L625 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-treatments-ah-wire)\"></path><rect x=\"545\" y=\"96\" width=\"160\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">accept</text><rect x=\"545\" y=\"132\" width=\"160\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">live with it</text><text x=\"625\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written, signed, dated</text></svg>", "caption": "Four answers to any risk. Each one ends with somebody accepting what is left."}
```

**Mitigate** (also called reduce or modify) means putting in a control that lowers the likelihood,
the impact or both. Changing the portal's default password and adding MFA mitigates R1 by removing
the vulnerability. An offline backup mitigates R2 by shrinking the impact. Most of this course is
about mitigation, which is why it is easy to forget it is only one of four.

**Transfer** (or share) means moving some of the consequences to somebody else, usually by
contract. Cyber insurance pays for the cleanup after an incident. Moving the shop's payments to a
payment provider means card numbers never touch the shop's server, and the provider carries that
part of the risk. **What cannot be transferred is the accountability.** If the shop's customers'
data leaks from a supplier the shop chose, the customers, the press and the ANPD still look at the
shop. Insurance pays money; it does not undo the harm.

**Avoid** (or terminate) means stopping the activity that creates the risk. The shop used to keep
copies of customers' ID documents "just in case"; deleting them and no longer asking for them
avoids the whole risk of leaking them. Avoidance is underused because it feels like giving
something up, and it is the only treatment that brings a risk to zero.

**Accept** (or retain) means deciding, knowingly, to live with the risk as it is. The shop accepts
R5: a flood is rare, the shop is on the third floor, and moving would cost far more than the
expected loss. **Acceptance is a legitimate decision, not a failure to decide**, as long as three
things are true: it is written down, it is signed by somebody with the authority to accept that
much risk, and it has a date to be reviewed.

| risk | treatment | what is done |
|---|---|---|
| R1 default portal password | mitigate | unique password, MFA, portal off the internet |
| R2 ransomware | mitigate and transfer | offline backup; insurance for the cleanup |
| R3 lost laptop | mitigate | disk encryption, so a lost laptop is only a lost device |
| R4 failed update | mitigate | test updates on a copy first |
| R5 flood | accept | signed by the owners, reviewed every year |

The difference between acceptance and neglect is the paperwork. A risk nobody looked at has not
been accepted; it has been ignored, and when it happens nobody can say whether it was a reasonable
bet or an oversight. Lesson 13 comes back to this, because auditors ask exactly that question.
