---
title: The parts of an alert rule
version: 1
---

**An alert rule watches a scope, evaluates a condition on a schedule, and fires an alert when the
condition is met.** Everything else is detail about those three.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"An alert rule drawn as a pipeline. A scope, the workspace log-shop, feeds a query evaluated every 5 minutes over the last 5 minutes. Its result is compared with a condition: more than 0 rows. If it is met, an alert with severity 1 is fired, and it goes through alert processing rules, which can remove the action groups during a maintenance window, before reaching the action group ag-shop-oncall, which e-mails and posts to a chat webhook.\"><defs><marker id=\"ah-rule\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">scope</text><text x=\"80\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">log-shop</text><rect x=\"165\" y=\"40\" width=\"140\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">query</text><text x=\"235\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every 5 min</text><rect x=\"330\" y=\"40\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">condition</text><text x=\"390\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">rows &gt; 0</text><rect x=\"475\" y=\"40\" width=\"225\" height=\"60\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"587\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">alert fired</text><text x=\"587\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">severity 1</text><path d=\"M140 70 L163 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><path d=\"M305 70 L328 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><path d=\"M450 70 L473 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><rect x=\"330\" y=\"140\" width=\"200\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processing rules</text><text x=\"430\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quiet during maintenance</text><rect x=\"555\" y=\"140\" width=\"145\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"627\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">action group</text><text x=\"627\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e-mail, webhook</text><path d=\"M587 100 L440 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><path d=\"M530 170 L553 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path></svg>", "caption": "The rule decides that something is wrong; the action group decides who hears; processing rules sit between the two."}
```

Azure Monitor has several kinds of rule; two matter most here. A **metric alert** watches a platform
metric, lesson 8's kind of signal: cheap, quick, evaluated every minute, and limited to what a metric can
say. A **log search alert** runs a KQL query against a workspace: as expressive as the language, and
bounded by how fast logs arrive, which is minutes rather than seconds. The shop uses metric alerts for
things like a VM's CPU and log search alerts for anything about what customers experienced, because only
the logs know which requests failed.

A log search alert has four settings worth understanding before writing one:

- **evaluation frequency**: how often the query runs;
- **window size**: how far back each run looks;
- **the condition**: how the query's result becomes yes or no, such as *the number of rows is greater
  than 0*, or *the value in a column is above a threshold*;
- **failing periods**: how many evaluations in a row must be yes before the alert fires, the defence
  against a single bad minute.

An alert has a **severity**, from 0 (critical) to 4 (verbose), which is the shop's way of saying who is
woken up and who reads it in the morning. And it is **stateful** when `autoMitigate` is on: it fires once,
stays fired while the condition holds, and resolves by itself when an evaluation comes back no. Without
it, every yes is a new alert, and a forty-minute incident is eight e-mails.

Rules are billed per rule per month, and a log search alert by how often it runs. None was created
here; the rest of this lesson writes them and checks what they would have done.
