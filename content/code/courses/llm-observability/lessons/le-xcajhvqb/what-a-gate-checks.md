---
title: What a regression test checks
version: 2
---

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four regression reports as pairs of bars, cases fixed and cases broken. From 2026.09.4 to 2026.10.1, the release that shipped: 2 fixed, 7 broken, cost down 34%. To 2026.10.2, the smaller model: 0 fixed, 7 broken, cost down 62%. To 2026.10.3, the floor put back: 7 fixed, 2 broken, cost up 50%. To 2026.10.4, both changes: 4 fixed, 7 broken, cost down 37%.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.09.4 → 2026.10.1</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the release that shipped</text><rect x=\"300\" y=\"42\" width=\"40\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"346\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"300\" y=\"56\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">7</text><text x=\"700\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−34%</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.2</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">smaller model</text><text x=\"306\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"300\" y=\"106\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">7</text><text x=\"700\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−62%</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.3</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">floor put back</text><rect x=\"300\" y=\"142\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">7</text><rect x=\"300\" y=\"156\" width=\"40\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"346\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2</text><text x=\"700\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+50%</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.4</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both</text><rect x=\"300\" y=\"192\" width=\"80\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><rect x=\"300\" y=\"206\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">7</text><text x=\"700\" y=\"204\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−37%</text><rect x=\"300\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">fixed</text><rect x=\"420\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"438\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">broken</text><text x=\"700\" y=\"19\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cost</text></svg>", "caption": "Cases fixed and broken against the release before, and the change in what the set costs to answer. Three of the four changes are cheaper, and all three break seven cases."}
```

The four reports give the rules a regression test enforces, and each was needed by one of them:

1. **The two runs asked the same questions.** `regress.py` refuses otherwise, and lesson 13's set
   version is what it compares against. A run of version 1 of the set is not comparable with one of
   version 2:

```
ana@dev:~/obs$ python evalrun.py v1 --release 2026.10.1 && python regress.py 2026.10.1 v1
runs/v1.jsonl: 24 questions, release 2026.10.1
runs/v1.jsonl did not ask the questions of data/eval-v2.jsonl: refusing to compare
EXIT 0
```

2. **No case goes from right to wrong without somebody reading it.** The release that shipped broke
   seven, at p = 0.18. The rule is about the cases, not the p-value.
3. **No check newly fails without somebody reading it.** The smaller model kept the right facts on
   most of the replies it changed, and broke the assistant's form on eleven of them; only the checks
   saw it.
4. **Cost and latency are reported beside the cases, with their direction.** The release that shipped
   and the smaller model were both cheaper, for bad reasons. Each needs a budget somebody agreed: how
   much more a release may cost, how much slower it may be, and how much cheaper it may be before
   somebody asks why.
5. **The number of changed replies is reported**, so that somebody reads them. e31 changed between two
   runs of the same settings, into a reply that contradicts its source and still passes the facts.

What it does not check is as important. **It does not say the candidate is good.** It says the
candidate is no worse than production on 32 questions. The held-out split, lesson 13's, is run once
the candidate is final; the production signals of lesson 5 take over after release, on the questions
nobody thought to put in a set.

Lesson 15 makes these rules a test that runs on every change, and fails the build when one is broken.
