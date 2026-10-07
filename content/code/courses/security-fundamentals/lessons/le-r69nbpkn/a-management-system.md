---
title: A management system, not a checklist
version: 1
---

The idea at the heart of 27001 is the **information security management system (ISMS)**: the
organisation's way of deciding, doing, checking and improving its security. It is not a piece of
software and not a set of controls. It is the policies, the roles, the processes and the records that
keep the controls appropriate as the organisation and its risks change.

That is why 27001 says comparatively little about firewalls and a great deal about management. The
requirements are in its **clauses 4 to 10**, and every one of them is mandatory for certification:

```schooling-figure
{"svg": "<svg id=\"sf-isms-clauses\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The clauses of ISO 27001 as a cycle. Clause 4, context, and clause 5, leadership, frame it. Then clause 6, planning; clause 7, support; clause 8, operation; clause 9, performance evaluation; clause 10, improvement; and back to planning.\"><defs><marker id=\"sf-isms-clauses-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4 context of the organisation  ·  5 leadership</text><rect x=\"30\" y=\"90\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6 planning</text><rect x=\"290\" y=\"90\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">7 support</text><rect x=\"550\" y=\"90\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">8 operation</text><rect x=\"420\" y=\"170\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"490.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">9 evaluation</text><rect x=\"160\" y=\"170\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">10 improvement</text><path d=\"M170 110 L290 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M430 110 L550 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M620 130 L620 190 L560 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M420 190 L300 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M160 190 L100 190 L100 130\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><text x=\"360\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plan · do · check · act</text></svg>", "caption": "Clauses 4 and 5 frame the system; 6 to 10 turn as a cycle that never stops."}
```

| clause | title | what it asks for, at the shop |
|---|---|---|
| **4** | context of the organisation | what the shop is, who cares about its security, and the scope of the ISMS |
| **5** | leadership | the owners commit, sign the security policy and assign roles |
| **6** | planning | assess and treat risks (lesson 3), and set security objectives |
| **7** | support | people, competence, awareness, communication and documented information |
| **8** | operation | carry out the risk treatment: the controls actually run |
| **9** | performance evaluation | monitor and measure, internal audit (lesson 13), management review |
| **10** | improvement | handle nonconformities, take corrective action, improve continually |

Read top to bottom, the clauses are a cycle: understand the situation, commit, plan, resource, do,
check, improve, and around again. Older writing calls it **plan, do, check, act**. The current text no
longer names the cycle, and the cycle is still how the clauses fit together.

### What the clauses demand that a checklist does not

Three requirements make an ISMS different from a list of good practices:

- **risk assessment drives the controls** (clause 6). The organisation chooses controls because its
  own risk assessment says it needs them, not because they appear in a catalogue. The risk register
  of lesson 3 is the heart of it.
- **leadership is accountable** (clause 5). Top management must show commitment, not delegate the
  whole subject to IT. An auditor will ask to talk to the owners, not only to ana.
- **the system checks and corrects itself** (clauses 9 and 10). Internal audits, a management review
  at planned intervals, and corrective actions with evidence that they were done. A certificate is not
  kept by being right once; it is kept by noticing and fixing what goes wrong.

The clauses also require **documented information**: the scope, the policy, the risk assessment
method and results, the statement of applicability (two sections on), and records showing that the
processes ran. Lesson 13's evidence is what fills those requirements.
