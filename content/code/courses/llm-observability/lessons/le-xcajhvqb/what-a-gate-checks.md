---
title: What a regression test checks
version: 1
---

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four regression reports as bars. From 2026.09.4 to 2026.10.1: 0 fixed, 5 broken, cost down 48%. To 2026.10.2, the new model: nothing fixed or broken, cost up 118%. To 2026.10.3, the floor put back: 5 fixed, none broken, cost up 93%. To 2026.10.4, both changes: 6 fixed, none broken, one check newly failing, cost up 341%.\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.09.4 → 2026.10.1</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the release that shipped</text><rect x=\"330\" y=\"43\" width=\"180\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"518\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">5</text><text x=\"700\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−48%</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.2</text><text x=\"20\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">new model</text><text x=\"330\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"700\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+118%</text><text x=\"20\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.3</text><text x=\"20\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">floor put back</text><rect x=\"330\" y=\"135\" width=\"180\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"518\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5</text><text x=\"700\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+93%</text><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.4</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">both, one check broken</text><rect x=\"330\" y=\"181\" width=\"216\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">6</text><text x=\"700\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+341%</text><rect x=\"330\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">fixed</text><rect x=\"450\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">broken</text><text x=\"700\" y=\"19\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cost</text></svg>", "caption": "Cases fixed and broken against the release before, and the change in what the set costs to answer. The cheapest change is the one that broke five cases."}
```

The four reports give the rules a regression test enforces, and each was needed by one of them:

1. **The two runs asked the same questions.** `regress.py` refuses otherwise, and lesson 13's set
   version is what it compares against. A run of version 1 of the set is not comparable with one of
   version 2:

```
ana@lab:~/obs$ python evalrun.py v1 --release 2026.10.1 && python regress.py 2026.10.1 v1
runs/v1.jsonl: 30 questions, release 2026.10.1
runs/v1.jsonl did not ask the questions of data/eval-v2.jsonl: refusing to compare
```

2. **No case goes from right to wrong without somebody reading it.** The release that shipped broke
   five, at p = 0.0625. The rule is about the cases, not the p-value.
3. **No check newly fails.** The combined candidate passed every fact it passed before and broke a
   rule about form; only the checks saw it.
4. **Cost and latency are reported beside the cases, with their direction.** The release that shipped
   was cheaper and faster for a bad reason; the new model was dearer for no reason the set can see.
   Each needs a budget somebody agreed: how much more a release may cost, how much slower it may be.
5. **The number of changed replies is reported**, so that someone reads them. A reply can change in
   ways no grader on the set measures.

What it does not check is as important. **It does not say the candidate is good.** It says the
candidate is no worse than production on 42 questions. The held-out split, lesson 13's, is run once the
candidate is final; the production signals of lesson 5 take over after release, on the questions
nobody thought to put in a set.

Lesson 15 makes these rules a test that runs on every change, and fails the build when one is broken.
