---
title: Measuring what the tests ran
version: 1
---

**Code coverage** is a record of which lines of your program ran while the tests ran. It answers a
narrow question exactly: *which code did no test execute?* It does not answer the question people
usually ask it, *are the tests good?*, and most of this lesson is about the distance between the
two.

In Python the tool is `coverage.py`. It runs a program, here pytest, with a tracer that notes every
line executed, and then reports per file. `shipquote`'s configuration from lesson 1 already tells
it what to measure:

```toml
[tool.coverage.run]
branch = true
source = ["shipquote"]

[tool.coverage.report]
show_missing = true
```

`source` limits the report to the project's own package, so the tests and the libraries are not
counted. `branch = true` asks for branch coverage as well as lines, which section 03 explains.
`show_missing` lists the lines that never ran.

```
ana@laptop:~/shipquote$ coverage run -m pytest -q
........ss.................................                              [100%]
41 passed, 2 skipped in 2.47s
ana@laptop:~/shipquote$ coverage report
Name                    Stmts   Miss Branch BrPart  Cover   Missing
-------------------------------------------------------------------
shipquote/__init__.py       0      0      0      0   100%
shipquote/app.py           54     12      8      3    76%   20-21, 23, 31, 36-38, 60-63, 67
shipquote/carrier.py       27     10      2      0    66%   16-19, 22-29
shipquote/dispatch.py      12      0      4      0   100%
shipquote/mailer.py        14      9      0      0    36%   8-9, 12-18
shipquote/money.py          9      1      2      1    82%   14
shipquote/orders.py         7      0      2      0   100%
shipquote/quote.py         19      0      6      0   100%
shipquote/store.py         19      0      0      0   100%
shipquote/version.py        3      0      0      0   100%
-------------------------------------------------------------------
TOTAL                     164     32     24      4    81%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 298\" role=\"img\" aria-label=\"Coverage per file of shipquote at step 7, as bars out of 100 percent. quote.py, dispatch.py, orders.py and store.py are at 100. money.py is at 82, app.py at 76. Two bars are highlighted: carrier.py at 66, whose only tests were skipped, and mailer.py at 36, which every test replaces with a mock. The total is 81 percent.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">coverage per file, step 7, total 81%</text><text x=\"188\" y=\"59\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">quote.py</text><rect x=\"200\" y=\"50\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"50\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"87\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">dispatch.py</text><rect x=\"200\" y=\"78\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"78\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">orders.py</text><rect x=\"200\" y=\"106\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"106\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">store.py</text><rect x=\"200\" y=\"134\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"134\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">100%</text><text x=\"188\" y=\"171\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">money.py</text><rect x=\"200\" y=\"162\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"162\" width=\"360.8\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"171\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">82%</text><text x=\"188\" y=\"199\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">app.py</text><rect x=\"200\" y=\"190\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"190\" width=\"334.4\" height=\"18\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"650\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">76%</text><text x=\"188\" y=\"227\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">carrier.py</text><rect x=\"200\" y=\"218\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"218\" width=\"290.4\" height=\"18\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"650\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">66%</text><text x=\"188\" y=\"255\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">mailer.py</text><rect x=\"200\" y=\"246\" width=\"440\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"246\" width=\"158.4\" height=\"18\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"650\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">36%</text><text x=\"200\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">highlighted: code whose only tests were skipped, or replaced by a mock everywhere</text></svg>", "caption": "The same report as a picture. The two short bars are not careless code: one is a class whose tests were skipped, the other a mailer no test ever runs for real."}
```

## Reading the table

Each row is a file. **Stmts** is the number of executable statements, **Miss** how many never ran,
**Branch** and **BrPart** the decision points and how many were only partly taken, **Cover** the
percentage, and **Missing** where to look.

The total is **81%**, and on its own the number says little. The rows say a lot:

- `quote.py`, `dispatch.py`, `orders.py` and `store.py` are at **100%**: the rules lessons 1 to 3
  tested.
- `carrier.py` is at **66%**, and its missing lines, 16 to 19 and 22 to 29, are the whole of
  `CarrierClient`. That is the contract test from lesson 2, **skipped because `CARRIER_URL` was not
  set**. The skip printed `ss` in the progress line; the coverage report turns it into a list of
  lines nobody checked.
- `mailer.py` is at **36%**. Lesson 2 replaced the mailer with an autospec mock everywhere, so the
  code that really talks to an SMTP server never runs in a test.
- `app.py` is at **76%**. Its missing lines include `/version`, the 404, the "missing parameter"
  answer, the 500 path, and `main()`.
- `money.py` misses one line, 14: the `raise` for `split` with fewer than one part.

Every one of those is a fact you can act on, and none of them is a judgement. **Uncovered code is
code that no test could have caught a bug in.** Covered code is code that ran; whether anybody
checked what it did is a different question, which section 04 asks.

## Where the numbers come from

Coverage instruments the interpreter, so anything that ran in the test process counts, including
the HTTP server, which the functional tests start in a thread. Code run in a **separate process**
does not count unless that process is measured too; a suite that starts the server with
`subprocess` would report `app.py` as untouched however many requests it sent. Section 09 shows how
separate measurements are put back together.
