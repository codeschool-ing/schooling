---
title: Testing the data, and testing the code
version: 1
---

Lessons 12 and 16 tested **the data**: every night, whatever arrived is checked against what should
be true of it. Those checks run in production, on real rows, and they answer *is tonight's data
right?* They cannot answer a different question that matters just as much: *is the code right?* A
transformation with a bug in it produces data that passes every test written by the same person
with the same misunderstanding, night after night.

Testing the code means running it on inputs whose right answer is known in advance, before it
reaches production, and that takes three kinds of test:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-pyramid\" aria-label=\"Three kinds of test for a pipeline, as layers. At the bottom, many unit tests: one function or one model, on made-up rows, fast. In the middle, a few integration tests: the whole pipeline in databases of its own, slower. Beside them, the fixture they run on: one real day of the shop. And apart from all three, the data tests of lessons 12 and 16, which run every night on real data.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"230.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">test the code, before a change</text><rect x=\"20.0\" y=\"46.0\" width=\"230.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">integration tests</text><text x=\"135.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the whole nightly · few, slower</text><rect x=\"290.0\" y=\"46.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a fixture of real data</text><text x=\"370.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one day of the shop</text><path d=\"M288.0 76.0 L252.0 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"126.0\" width=\"430.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">unit tests</text><text x=\"235.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one rule, made-up rows · many, fast</text><path d=\"M480.0 16.0 L480.0 210.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">test the data, every night</text><rect x=\"505.0\" y=\"86.0\" width=\"195.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">data tests</text><text x=\"602.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every night, on real data</text></svg>", "caption": "Tests of the code run on known inputs before a change; tests of the data run on whatever arrived, every night."}
```

- **Unit tests** run one piece — a function, a model — on a handful of inputs made up to exercise
  one rule each. They are fast, there are many of them, and when one fails it points at one line.
- **Integration tests** run the pipeline end to end, on a database of their own, and check what
  comes out against answers worked out some other way. They are slower, there are few of them, and
  they find the bugs that live between pieces: a column renamed in one place and not another, a
  connection string, a lock.
- **The fixture** that integration tests run on. Made-up data tests what its author thought of.
  **A slice of real data** — one day of the shop, cut out and kept — tests what the shop actually
  does, including the things nobody thought of: the walk-in customers of lesson 12, the erased
  ones, the late refunds.

This lesson writes all three for Ana's pipeline, and each one finds something.
