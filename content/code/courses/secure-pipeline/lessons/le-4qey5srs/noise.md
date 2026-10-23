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

@@FIGURE decide@@

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
