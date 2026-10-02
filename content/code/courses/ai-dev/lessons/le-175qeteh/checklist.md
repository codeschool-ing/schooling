---
title: A checklist for a feature that uses a model
version: 1
---

The course has built one shop feature at a time. Before any of them reaches a customer, **the same
questions apply**, and every one of them points back to a lesson that showed the failure and the
fix.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Nine questions to answer before a feature that uses a model ships, each with the lessons that cover it: cost, lessons 2 and 10; quality, 4 and 5; facts, 6; tools, 7 and 8; failure, 9 and 10; data, 10 and 11; output, 11; dependencies, 11; an off switch, 11.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cost</text><text x=\"125.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lessons 2, 10</text><rect x=\"250\" y=\"16\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quality</text><text x=\"355.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lessons 4, 5</text><rect x=\"480\" y=\"16\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">facts</text><text x=\"585.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 6</text><rect x=\"20\" y=\"80\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tools</text><text x=\"125.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lessons 7, 8</text><rect x=\"250\" y=\"80\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">failure</text><text x=\"355.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lessons 9, 10</text><rect x=\"480\" y=\"80\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">data</text><text x=\"585.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lessons 10, 11</text><rect x=\"20\" y=\"144\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">output</text><text x=\"125.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 11</text><rect x=\"250\" y=\"144\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dependencies</text><text x=\"355.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 11</text><rect x=\"480\" y=\"144\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">off switch</text><text x=\"585.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lesson 11</text></svg>", "caption": "Every question points back to a lesson that showed the failure and the fix."}
```

## Before it ships

- **Cost**: the tokens per request counted, the month priced, a budget and a limit on the key
  (lessons 2 and 10).
- **Quality**: an evaluation with real cases, run on every change to the prompt or the model
  (lessons 4 and 5).
- **Facts**: answers grounded in retrieved sources and citations checked by code where facts matter
  (lesson 6).
- **Tools**: each task offered only what it needs; schemas enforced; writes approved by a person or
  bounded by rules; idempotency keys on anything that changes state (lessons 7 and 8).
- **Failure**: timeouts set, retries understood, a fallback tested by breaking the first provider,
  partial streams marked (lessons 9 and 10).
- **Data**: less sent, the rest redacted, the provider's terms read for the plan in use, logs
  without content (lessons 10 and 11).
- **Output**: escaped for where it goes, never pasted into SQL or a shell, checked for promises a
  tool result does not back (lesson 11).
- **Dependencies**: every package a model suggested looked up before it was installed (lesson 11).
- **Off switch**: one that works, used at least once (lesson 11).

## And after

**A feature that uses a model changes without a deploy**: the provider updates a model, prices
move, the emails customers write change. Keep the evaluation running on a schedule, read the
cost and the error rate every week, and treat a sudden change in either as an incident until it
is explained.
