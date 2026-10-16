---
title: What a model's version has to name
version: 1
---

Lesson 5's `train.py` wrote a record beside the model: the training file's fingerprint, the cutoff,
the row count, the library version. **It names the data and not the code**, and it is one file on
one disk, overwritten by the next run. Ask it which model sent last month's vouchers and whether that
model can be built again, and it has no answer.

**A model is the product of four things**, and a version that leaves one out cannot be rebuilt:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l07-four-inputs\" aria-label=\"Four inputs feed one model version: code, kept by Git; data, kept by DVC; settings, written in files kept by Git; and the environment, pinned by the pip lines. The model version produces the model file, kept by DVC, and its scores, kept in Git and in MLflow.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">code</text><text x=\"105.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Git</text><path d=\"M190.0 44.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"20.0\" y=\"82.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">data</text><text x=\"105.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">DVC</text><path d=\"M190.0 106.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"20.0\" y=\"144.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">settings</text><text x=\"105.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Git</text><path d=\"M190.0 168.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"20.0\" y=\"206.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">environment</text><text x=\"105.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pinned versions</text><path d=\"M190.0 230.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"290.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">one model version</text><rect x=\"530.0\" y=\"70.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the model file</text><text x=\"615.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">DVC, MLflow</text><path d=\"M452.0 140.0 L528.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"530.0\" y=\"160.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">its scores</text><text x=\"615.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Git, MLflow</text><path d=\"M452.0 140.0 L528.0 186.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path></svg>", "caption": "Leave out any of the four and the version cannot be rebuilt. The model file and its scores are outputs, and they are versioned as well."}
```

| input | what changes it | what keeps its versions here |
| --- | --- | --- |
| **code** | an edit to `features.py`, `model.py` or any step | **Git**, as commits |
| **data** | a new night of purchases, a corrected load | **DVC**, as content hashes, with the files in a store of its own |
| **settings** | the cutoffs, a model's parameters | Git, because they are written in `dvc.yaml` and `model.py` |
| **environment** | a new scikit-learn | the pinned `pip install` lines, and the version each run records |

And then two things that are not inputs but have to be versioned too: **the model file itself**, the
output of all four, and **its scores**, so that two versions can be compared without retraining
either.

Three tools, each doing one job:

- **Git** you know. It is good at text and bad at large binary files, which is the gap the other two
  fill;
- **DVC**, Data Version Control, keeps large files out of Git: it stores them in a cache and a
  remote of its own, and puts a small text file in Git that names each one by its hash. It also runs
  the pipeline, and reruns only the steps whose inputs changed;
- **MLflow** records each training run (its parameters, scores and files) in a database you can
  search, and keeps a **model registry**: named models with numbered versions, and aliases such as
  `champion` that a service can load by name.

**The three overlap, and that is normal.** DVC can track metrics and MLflow can store data. This
lesson gives each the job it is best at, which is also the division most teams settle on.
