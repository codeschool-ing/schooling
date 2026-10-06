---
title: The stages of a delivery pipeline
version: 1
---

A delivery pipeline is the integration pipeline of lessons 5 and 6 with more stages after it. The
stages differ from team to team; their **order** does not, and the order is what makes the pipeline
worth trusting:

1. **Build** the artifact from the commit, once.
2. **Test** it: everything lessons 1 to 4 built, in the matrix of lesson 5.
3. **Deploy to staging**, an environment made to resemble production, and **smoke-test** it there.
4. **Pass the gate**: a person's approval, or an automated rule, or both.
5. **Deploy the same artifact to production**, and smoke-test it there too.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Five stages in a row: build, test, staging with a smoke test, the gate, production with a smoke test. A dashed line under them says the same artifact, built once, travels through every stage.\"><rect x=\"20\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build</text><rect x=\"160\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">test</text><path d=\"M140 75 L154 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M153 71 L160 75 L153 79 z\" fill=\"var(--paper-dim)\"></path><rect x=\"300\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">staging + smoke</text><path d=\"M280 75 L294 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M293 71 L300 75 L293 79 z\" fill=\"var(--paper-dim)\"></path><rect x=\"440\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">gate</text><path d=\"M420 75 L434 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M433 71 L440 75 L433 79 z\" fill=\"var(--paper-dim)\"></path><rect x=\"580\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">production + smoke</text><path d=\"M560 75 L574 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M573 71 L580 75 L573 79 z\" fill=\"var(--paper-dim)\"></path><path d=\"M80 120 L80 140 L640 140 L640 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">one artifact, built once, sha256 checked at every deploy</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each stage starts only if the one before passed</text></svg>", "caption": "A delivery pipeline. The artifact moves forward and is never rebuilt, so what reaches production is what passed everything before it."}
```

Each stage only starts if the one before passed, and each takes **the artifact from the stage
before** rather than building its own. So a production deploy is, by construction, the deploy of
bytes that passed every earlier stage. That is what "promote" means: the artifact moves forward; it
is never rebuilt.

## Fast failure, again

The order also puts cheap and likely failures first, for the reason lesson 6 section 07 gave about
steps. A unit test fails in seconds on the build machine. A broken configuration fails in staging,
minutes later, before any user. **Production should be the stage where nothing new is learnt**, only
confirmed: the same artifact, the same deploy command, the same smoke test, a different
configuration.

## This repository's pipeline

The release workflow that publishes this course follows the same shape, as jobs:

| job | what it does | what it needs |
|---|---|---|
| `Tag` | refuses a malformed tag, a tag lower than the last release, or one not on `main` | nothing |
| `Checks` | runs the whole CI workflow, called rather than copied | `Tag` |
| `Publish` | builds, asks the binary its version, creates the release | `Checks` |
| `Deploy` | pushes the images and moves the service to the new revision | `Publish` |

Its `Deploy` job runs one at a time and is never cancelled halfway, which lesson 6 section 09 read
from its `concurrency` block. What it does not have is a staging environment: the repository serves
one small platform, and its authors have decided its risk does not need one. Lesson 8 asks when that
decision is right.

## What a pipeline produces

A run of a delivery pipeline leaves three things behind: an artifact with a hash, a record of every
stage it passed, and a deployment that names its version. Together they answer the question every
incident starts with, **what changed and when**, without anybody having to remember.
