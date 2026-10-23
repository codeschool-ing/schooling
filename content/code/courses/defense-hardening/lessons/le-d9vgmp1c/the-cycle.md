---
title: A cycle, not a scan
version: 1
---

**Vulnerability management is the routine of finding the flaws in what you run and getting them
fixed before somebody uses them.** The common picture is a tool: buy a scanner, run it, read the
report. The scanner is one step of five, and the steps people skip are the ones after the report,
which is why most organisations that scan regularly still have findings years old.

The five steps go round:

| step | the question it answers |
|---|---|
| **discover** | what do we run, on which machines, in which versions? |
| **assess** | which published flaws apply to those versions? |
| **prioritise** | which of them matter first, here, and by when? |
| **remediate** | patch, reconfigure, remove, or accept with a reason |
| **verify** | is the flaw gone, measured the same way it was found? |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-cycle\" aria-label=\"Five steps around a circle: discover what runs, assess which flaws apply, prioritise and set a date, remediate by patching, reconfiguring, removing or accepting, and verify with the same check that found the flaw, which leads back to discover. Discover is marked as lesson 18 and remediate as lesson 17; assess, prioritise and verify are this lesson.\"><defs><marker id=\"l16-cycle-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M428.0 76.0 L481.7 96.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M531.2 152.6 L495.8 209.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M409.3 239.9 L310.7 239.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M224.2 209.9 L188.8 152.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M238.3 96.6 L292.0 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><rect x=\"298.0\" y=\"26.0\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">discover</text><text x=\"360.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 18</text><rect x=\"487.7\" y=\"98.6\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"549.7\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">assess</text><text x=\"549.7\" y=\"133.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this lesson</text><rect x=\"415.3\" y=\"215.9\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"477.3\" y=\"232.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">prioritise</text><text x=\"477.3\" y=\"250.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this lesson</text><rect x=\"180.7\" y=\"215.9\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"242.7\" y=\"232.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">remediate</text><text x=\"242.7\" y=\"250.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 17</text><rect x=\"108.3\" y=\"98.6\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.3\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">verify</text><text x=\"170.3\" y=\"133.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this lesson</text></svg>", "caption": "The scan is one step of five. The ones after the report are the ones that get skipped."}
```

The first step is lesson 18's subject, and it is the one everything else depends on: an advisory
about a package you do not know you run is an advisory nobody acts on. The fourth step is lesson
17's, where a fix is rolled out without breaking the portal. This lesson is about the three in the
middle and the last one: **reading what is installed, matching it against what is known, deciding
what comes first, and setting a date by which it has to be done.**

## Why a date is part of the subject

A finding with no deadline is a finding that waits. Every organisation has more vulnerabilities than
people to fix them; the ordinary state of a backlog is that it grows. What turns the cycle into a
programme is that each finding gets an owner and a due date when it is found, and that a missed date
is visible to somebody who can do something about it.

**A deadline is a decision about risk, written in days.** The firm decides, in advance and in
writing, how long each kind of finding may stay open. That decision is the policy at the top of the
script in this lesson's section on prioritising, and the last section is about keeping to it.

## The lab for this lesson

Start `web`, whose packages are what you will assess, and `admin`, where the scripts run:

```sh
sudo bash hostlab.sh up web admin
```

`web` comes up as `hostlab.sh` builds it, with the FTP server and the other services that lesson 1
removed back in place, because every lesson starts from a fresh lab. That turns out to matter in the next sections.
