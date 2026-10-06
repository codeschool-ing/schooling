---
title: Six functions
version: 1
---

**NIST**, the US National Institute of Standards and Technology, publishes a great deal of security
guidance, and two of its documents are used far beyond the United States. The first is the
**Cybersecurity Framework (CSF)**: a common language for what a security programme should achieve. It
was first published in 2014, revised in 2018, and its current version, **CSF 2.0**, came out in February
2024. Using it is voluntary, it costs nothing, and it is meant for organisations of any size and sector.

The CSF organises everything into **six functions**:

```schooling-figure
{"svg": "<svg id=\"sf-csf-wheel\" viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The six functions of NIST CSF 2.0. Govern sits at the centre. Around it, in order: identify, protect, detect, respond and recover.\"><circle cx=\"360\" cy=\"140\" r=\"50\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><text x=\"360\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">GOVERN</text><text x=\"360\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">GV</text><rect x=\"298\" y=\"18\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">identify</text><text x=\"360\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ID</text><rect x=\"488\" y=\"87\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">protect</text><text x=\"550\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">PR</text><rect x=\"415\" y=\"199\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"477\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">detect</text><text x=\"477\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DE</text><rect x=\"181\" y=\"199\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"243\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">respond</text><text x=\"243\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RS</text><rect x=\"108\" y=\"87\" width=\"124\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recover</text><text x=\"170\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RC</text></svg>", "caption": "Govern in the middle, directing the five that were there since 2014."}
```

| function | the question it answers | at the shop |
|---|---|---|
| **Govern** | how are security decisions made, and who is accountable? | the owners' risk appetite, roles, policy (lessons 3, 13) |
| **Identify** | what do we have, and what are the risks to it? | the asset list and the risk register (lessons 2, 3) |
| **Protect** | what safeguards keep things from going wrong? | segmentation, least privilege, MFA, backups (lessons 5, 6, 9, 12) |
| **Detect** | how do we notice when something goes wrong? | the portal's log and the detection rule (lessons 10, 11) |
| **Respond** | what do we do about a detected incident? | revoke the leaked password, contain, communicate |
| **Recover** | how do we get back to normal? | restore from backup within the RTO (lesson 12) |

The first five functions were there from 2014. **Govern** is new in 2.0, and the figure puts it in the
middle on purpose: it is about how the other five are directed, by whom, and against what appetite for
risk. In version 1.1 most of that lived inside Identify, and organisations kept treating security as a
technical matter for IT. Pulling governance out into its own function is the framework saying, as
ISO 27001's clause 5 does, that security is a leadership responsibility.

### Why six functions are useful

The functions are not steps to do in order; an organisation does all six all the time. Their value is
as a **checklist for balance**. Most organisations, left alone, put nearly all their effort into
Protect, because it is the visible, buyable part, and then discover during an incident that they had
no way to Detect it and no practised way to Recover. Laying the shop's activities out under the six
functions shows the gaps at a glance, which is the same use lesson 4 made of the table of control
functions.
