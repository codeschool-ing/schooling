---
title: Six places, and the time each one can spend
version: 1
---

The question "should this check run earlier?" has no answer on its own. The useful question is
**"which place can afford it?"**, and every place on the line has a budget: the time a person will
wait there before they stop waiting and do something else. A check that fits the budget of a place
runs there. A check that does not fit goes further right, to a place that can afford it, and is
not dropped.

### The budgets

| place | when it runs | the budget | what fits there |
|---|---|---|---|
| editor | as you type or save | under a second | a linter, one Semgrep rule on one file |
| pre-commit hook | on `git commit` | a few seconds | a scan of the staged lines for secrets (lesson 6) |
| every push | on each push, every branch | **about ten minutes** | tests, static analysis, dependency audit, build, image scan |
| after the merge to main | on `main` only | as long as a push | publishing what passed; in linkbox, the image's `main` tag (lesson 8) |
| nightly | once a day, on `main` | an hour or more | a rebuild with no cache, the dynamic scan (lesson 4) |
| production | all the time | none: it never ends | new advisories against what is running, runtime alerts |

The numbers are rules of thumb, and the one for a push has a long history. Kent Beck's *Extreme
Programming Explained* made the **ten-minute build** a practice of its own, and *Continuous
Delivery* by Jez Humble and David Farley asks the same of a commit's first stage: under ten
minutes, and better under five. The reason is human rather than technical. **Ten minutes is about
as long as somebody will wait for an answer before they switch to another task.** Once they have
switched, a red build interrupts the new task instead of finishing the old one.

### Fast checks and slow ones

A check is fast or slow for one of three reasons, and which one decides what can be done about it.

- **It reads little.** A linter on one file, a secret scan of the staged lines. Fast anywhere.
- **It reads a lot, but only what changed.** The tests of a service, Bandit on its code. Fast while
  the service is small: lesson 3's Bandit run reads the 69 lines of linkbox's code, where a
  monolith has hundreds of thousands.
- **It has to build or run something first.** An image scan needs an image; a dynamic scan needs
  a running copy of the service and then walks every page it can find. Slow by nature, and the
  usual candidates for the nightly list.

**The second kind is where budgets are lost quietly.** Each check is fast when it is added, and the
service grows under all of them at once. That is why the next two sections measure linkbox's
pipeline instead of guessing, and why the pipeline prints a time for every stage it runs.

### One check, several places

A check is not confined to one place. The secret scan of lesson 6 runs in the pre-commit hook,
where it reads only the staged lines, and again as the first stage of
every push, where it reads the whole history. The two are the same tool with different inputs,
and **the second exists because the first can be skipped**: a hook lives in one person's clone and
`git commit --no-verify` bypasses it. A check that matters is never only on the laptop.

The build is the other example. The image is built on every push from layers cached by earlier builds,
which is what keeps the build stage short. The nightly list builds it again with no cache at all,
so **a build that only works because of what is cached** is found on an ordinary night, and not on
the day an urgent fix needs a clean build.

### Two lists for linkbox

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l02-lists\" aria-label=\"Two triggers, one runner. A git push on any branch makes the CI server run ci/pipeline.sh with ci/stages, test then build, and the verdict comes back in the push. A schedule at night clones main and runs ci/pipeline.sh twice, first with ci/stages and then with ci/nightly, whose one stage is rebuild, and the verdict has to be sent to somebody in the morning.\"><defs><marker id=\"sp-l02-lists-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l02-lists-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">git push</text><text x=\"80.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">any branch</text><rect x=\"15\" y=\"140\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">schedule</text><text x=\"80.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main, at night</text><rect x=\"185\" y=\"30\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/stages</text><text x=\"260.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test, build</text><rect x=\"185\" y=\"130\" width=\"150\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/stages</text><text x=\"260\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">then</text><text x=\"260\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/nightly</text><text x=\"260\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rebuild</text><rect x=\"375\" y=\"30\" width=\"150\" height=\"176\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/pipeline.sh</text><rect x=\"565\" y=\"30\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">in the push</text><text x=\"635.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seconds later</text><rect x=\"565\" y=\"140\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sent to a person</text><text x=\"635.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in the morning</text><path d=\"M145 58 L183 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M145 168 L183 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M335 58 L373 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M335 168 L373 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M525 58 L563 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M525 168 L563 168\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-amber)\"></path></svg>", "caption": "The two lists share the runner. What the nightly run adds is a list, not a second pipeline."}
```

So linkbox's pipeline gets two lists. `ci/stages` is what runs on every push, and it has to stay
inside the push budget as the course adds stages to it. `ci/nightly` is what runs once a day on
`main`, after everything in `ci/stages` has passed. This lesson starts the second list with one
stage, a rebuild of the image with no cache, and lesson 4 adds the dynamic scan to it. **Whatever
moves from the first list to the second is still run, every day, on the code that is actually on
`main`.**
