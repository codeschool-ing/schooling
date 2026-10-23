---
title: Why gates get switched off
version: 1
---

A quality gate is a check that decides whether a change may go on: the build breaks, and nothing
merges until somebody acts. The common belief is that a stricter gate is a safer one, so every
finding should break the build. **A gate that breaks on things nobody can fix is switched off
within weeks**, and a gate that is off is less safe than one that warns.

### How a gate dies

Lesson 1 opened with the scanner that had been red for a month. Nobody decided to ignore it. It
broke the build on findings the person pushing could not fix, such as an advisory with no fixed
version or a warning about code from three years ago, so the team learnt that red meant nothing.
The next step is always the same, and it is always one line:

| where | the line that turns a gate into a decoration |
|---|---|
| GitLab CI | `allow_failure: true` on the job |
| GitHub Actions | `continue-on-error: true` on the step |
| this course's pipeline | the stage's name commented out of `ci/stages` |
| a laptop | `git commit --no-verify` |

And in any shell stage at all, `|| true` at the end of the command.

Each is reviewed in a minute and approved, because the reviewer has seen the same red build for a
month too. None of them is reverted when the noise stops, because nobody is watching for that.
The two hosted keywords come from GitLab's and GitHub's documentation and were not run here. This
is **alert fatigue**: a signal that fires on noise trains its readers to stop reading, and then
the true finding arrives in a channel nobody opens.

### The bar this course uses

The whole lesson argues from one rule, already met as a habit in lesson 1:

**A check breaks the build only for something the person who broke it can fix, now, in the change
they are making.** Everything else is a warning, counted and shown and owned by somebody, or
nothing at all.

The rule has two halves, and each one excludes a common kind of noise. *Can fix* excludes the
advisory with no fixed version: the developer cannot publish a release of somebody else's
library. *Now, in the change* excludes old findings in code the change did not touch: breaking
Tuesday's change because of Monday's debt punishes the wrong person and teaches them that the
gate is unfair.

Two kinds of finding sit above the rule. **A secret always breaks**, because its owner can always
act at once, by revoking it, and waiting costs more every minute. And **a check that did not run
breaks too**: a scanner that crashed, timed out or never started has said nothing, and treating
silence as a pass is how a pipeline goes green while checking nothing. That is called failing
closed, and the gate of this lesson is built around it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l07-decide\" aria-label=\"The order in which a finding is judged. First, did the check run to the end? If not, break. Then, is it a secret? If so, break. Then, is an exception in force for it? If so, pass, with a warning in the exception's last week. Last, can the person who pushed fix it in this change? If so, break; if not, warn, with an owner.\"><defs><marker id=\"sp-l07-decide-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l07-decide-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"sp-l07-decide-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l07-decide-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">did the check</text><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run to the end?</text><rect x=\"195\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">is it</text><text x=\"270\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a secret?</text><rect x=\"375\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">is an exception</text><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in force?</text><rect x=\"555\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">can the pusher fix it</text><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in this change?</text><path d=\"M165 61 L193 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper-dim)\"></path><text x=\"179\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><path d=\"M345 61 L373 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper-dim)\"></path><text x=\"359\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><path d=\"M525 61 L553 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper-dim)\"></path><text x=\"539\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"15\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">break</text><path d=\"M90 92 L90 158\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-amber)\"></path><text x=\"96\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"195\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">break</text><path d=\"M270 92 L270 158\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-amber)\"></path><text x=\"276\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"375\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">pass</text><text x=\"450.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">warns in its last week</text><path d=\"M450 92 L450 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-phosphor)\"></path><text x=\"456\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"555\" y=\"160\" width=\"72\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">break</text><path d=\"M580 92 L580 158\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-amber)\"></path><text x=\"586\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"633\" y=\"160\" width=\"72\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"669.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">warn</text><text x=\"669.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">owned</text><path d=\"M680 92 L680 158\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper)\"></path><text x=\"686\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text></svg>", "caption": "Four questions, in this order. Only the last one is a judgement about the finding; the first two break the build whatever it is."}
```

### Three verdicts, and what each one promises

| verdict | what it promises the person reading it |
|---|---|
| break | this is yours, it is fixable, and nothing merges until it is fixed or excepted |
| warn | this is real, nobody can fix it in this change, and somebody named owns it |
| pass | every check ran to the end and found nothing it was told to report |

The promise of a pass is the one most often broken, by a stage that exits 0 because its scanner
could not run. The promise of a warning is the one most often forgotten: a warning with no owner
is noise, and the gate that produces it is on its way to being switched off. The next section
turns the three verdicts into exit statuses the pipeline can act on, and the four after it apply
them to six cases, one decision each.
