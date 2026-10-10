---
title: The first on-call shift
version: 1
---

Being on call is the part of an engineering job that new people dread most, with reason: alone, at
night, responsible for something they may barely understand, with clinics depending on it. Thiago's
experience in lesson 6, paged at three in the morning for an alert nobody had explained, is what
happens when the first on-call shift is treated as an ordinary rota entry. **A first shift is a
training stage, built in steps, with the new person never truly alone until they have done each step
with somebody.**

## Three steps

Agenda now uses a sequence that many teams use in some form:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l18-oncall\" aria-label=\"Three steps from left to right. Shadow: the new person is paged but the experienced engineer acts; Lucas with Yara in month two. Reverse shadow: the new person acts and the experienced engineer watches, ready to step in; Lucas with Yara in month three. Primary with a named backup: the new person is on call alone, with somebody who has agreed to answer at any hour; Lucas, with Diego as backup, after ninety days.\"><defs><marker id=\"l18-oncall-pl-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"130.0\" width=\"200.0\" height=\"125.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">shadow</text><text x=\"130.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">paged, watches;</text><text x=\"130.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Yara acts</text><text x=\"130.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">month 2</text><path d=\"M234.0 160.0 L256.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-oncall-pl-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"90.0\" width=\"200.0\" height=\"165.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">reverse shadow</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">acts; Yara watches,</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ready to step in</text><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">month 3</text><path d=\"M464.0 120.0 L486.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-oncall-pl-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"50.0\" width=\"200.0\" height=\"205.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">primary, with backup</text><text x=\"590.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alone, Diego answers</text><text x=\"590.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">at any hour</text><text x=\"590.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">after 90 days</text><text x=\"30.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">Lucas, never alone until each step was done with somebody</text></svg>", "caption": "The first primary week comes after the shadow and the reverse shadow, not instead of them."}
```

1. **Shadow.** The new person is paged alongside the primary for a week. They watch, ask, and take
   notes, but the primary acts. The goal is to see real alerts, real runbooks and real decisions.
2. **Reverse shadow.** The new person is primary and acts, with the experienced engineer paged
   alongside, watching, ready to step in. The goal is to make the decisions with a safety net.
3. **Primary, with a named backup.** The new person is on call alone, with a backup who has agreed to
   answer at any hour, and a runbook page for every alert that can page them.

Lucas did his shadow week in his second month, with Yara, and his reverse-shadow week in his third,
again with Yara. His first primary week came after the ninety days, with Diego as backup.

## What has to exist first

The steps only work if the system is ready for a new person to be on call:

- **Every alert that can page somebody has a runbook page**, saying what it means and what to try
  first. The one that woke Thiago did not; it does now, and the team has since agreed that an alert
  without a page cannot be turned on.
- **Escalation is written down**: who the backup is, how to reach them, and that calling them is
  expected, not a failure. Thiago's answer in lesson 6, that he had not wanted to wake anybody, is the
  problem this solves.
- **Decisions a person may need to make at night have owners**, as lesson 4's list required. The
  on-call engineer may turn off a feature flag without asking; that is now written in the runbook.

## After the first primary week

Renata spends part of the next one-to-one on how it went, using the questions from lesson 6: what was
the worst moment, from one to ten how ready did you feel, what would make it one point higher. Lucas's
answer was a seven, and the point higher was a runbook page for the database failover alert, which had
fired once and which he had not understood. He wrote the page himself, with Fábio's help, and that was
the last line of his ninety-day plan crossed off.

## Your task

For a team you know, write the on-call onboarding for a new person in your notebook, in the three
steps. Then check:

- Each step has a named experienced person and a week.
- Every alert that can page the new person has a page saying what to do.
- The new person knows, in writing, that calling the backup at night is expected.
- There is a conversation planned after the first primary week.
