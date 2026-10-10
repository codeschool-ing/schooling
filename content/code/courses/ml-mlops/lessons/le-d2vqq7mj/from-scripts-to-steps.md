---
title: From scripts to steps
version: 1
---

Every program so far did its whole job at once: build the examples, fit, print. **That is the right
shape for finding out, and the wrong one for running every month**, for four reasons each of the
earlier lessons ran into:

- **the files are found by accident.** `features.py` opens `shop.db` relative to wherever the
  program was started, and lesson 1's last setup failure showed what that does from the wrong
  directory: an empty database, created silently;
- **the dates are inside the code**, so the cutoff a model was trained on is a line somebody has to
  remember to change, and nothing stops them choosing one whose labels are unfinished;
- **nothing is checked.** A dataset with a negative recency in it trains a model as happily as a
  correct one;
- **nothing is kept.** The model exists while the program runs and is gone when it ends, and so is
  any record of which rows made it.

A pipeline fixes all four by splitting the work into **steps that pass files to each other**, each
of which can be run, checked and rerun alone:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-steps\" aria-label=\"The pipeline as four steps passing files. shop.db goes into build_dataset.py, which writes train.csv and test.csv. validate.py reads them and passes or refuses. train.py reads train.csv and writes lapse.joblib with its record, lapse.json. evaluate.py reads the model and test.csv and writes lapse.scores.json.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"14.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.db</text><path d=\"M105.0 42.0 L105.0 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"30.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build_dataset.py</text><text x=\"105.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refuses unfinished labels</text><path d=\"M180.0 107.0 L198.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"40.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">train.csv</text><rect x=\"40.0\" y=\"198.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">test.csv</text><rect x=\"200.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">validate.py</text><text x=\"275.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refuses broken rows</text><path d=\"M350.0 107.0 L368.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"210.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">exit 0 or 1</text><rect x=\"370.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">train.py</text><text x=\"445.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">records its data</text><path d=\"M520.0 107.0 L538.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"380.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lapse.joblib</text><rect x=\"380.0\" y=\"198.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lapse.json</text><rect x=\"540.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">evaluate.py</text><text x=\"615.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">scores the saved file</text><rect x=\"550.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lapse.scores.json</text></svg>", "caption": "Each step is a program with a file in and a file out. Any one of them can be run, checked and rerun alone, and a failure stops the ones after it."}
```

The first thing every step needs is to find the project's files the same way whatever directory it
is started from. Save this as `project.py`:

```python
"""project.py: where the project's files are, named in full, whatever directory runs it."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SHOP = ROOT / "shop.db"
DATA = ROOT / "data"
MODELS = ROOT / "models"
LABEL_DAYS = 90
```

`Path(__file__).resolve().parent` is the directory the file itself lives in, so `SHOP` is always
`~/ml/shop.db`, named in full. `LABEL_DAYS` is the label window, written once, because two steps
need it and a second copy is a second value one day.
