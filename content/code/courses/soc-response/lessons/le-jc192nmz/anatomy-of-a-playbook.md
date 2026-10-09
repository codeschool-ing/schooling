---
title: The anatomy of a playbook
version: 1
---

A **playbook** is the written sequence for one kind of alert. Automated or not, every good one has the same
five parts:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A playbook as five boxes in a row: trigger, enrich, decide, act, record. Between decide and act sits a person who approves; a dashed line from decide goes straight to record when nothing may be done automatically.\"><rect x=\"10\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">trigger</text><rect x=\"150\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">enrich</text><rect x=\"290\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decide</text><rect x=\"470\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">act</text><rect x=\"610\" y=\"50\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">record</text><path d=\"M110 73 L150 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M150 73 L142.0 69.0 L142.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M250 73 L290 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M290 73 L282.0 69.0 L282.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M390 73 L470 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M470 73 L462.0 69.0 L462.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"430\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a person</text><text x=\"430\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">approves</text><path d=\"M570 73 L610 73\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M610 73 L602.0 69.0 L602.0 77.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M340 96 L340 140 L660 140 L660 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M660 96 L656.0 104.0 L664.0 104.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"500\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing a machine may do</text></svg>", "caption": "The machine does the gathering and the paperwork. Between deciding and acting, a person."}
```

**Trigger**: which alert starts it, and with which fields (here, the address the alert grouped by).
**Enrich**: the facts gathered before anybody decides. **Decide**: which actions the facts justify, and
which of them a machine may take. **Act**: the change itself, through the target system's own interface.
**Record**: a ticket with what was known, what was proposed, what was done and by whose authority, written
on every run, including the runs that did nothing.

The arrow labelled *a person approves* is a choice, not a law. Some teams let a playbook block an address
with nobody in the loop, after months of measuring that it was right. The safe order is the opposite of the
tempting one: **start with every action approved by a person, and remove the approval for one action at a
time, when the record shows it has earned it.**

The dashed path matters as much as the solid one. When the facts say "this is the backup provider", the
playbook still writes its ticket and still tells somebody. A playbook that silently does nothing is
indistinguishable from one that failed.
