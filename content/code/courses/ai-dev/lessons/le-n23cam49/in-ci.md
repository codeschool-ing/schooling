---
title: An assistant in the pull request
version: 1
---

The same review of lesson 4 section 02 can run without anybody asking: a bot that reads every pull
request and posts its findings as comments. Several products do this, and a team can build one with
an API key and a CI job. **It is useful in exactly the way a careful colleague's first read is
useful, and dangerous in the same way an unchecked one would be.**

## What it does well

- **It reads every pull request**, including the small ones nobody reviews closely and the ones that
  arrive late on a Friday.
- **It is good at the local, mechanical findings**: an off-by-one at a boundary, an error ignored, a
  resource never closed, a test that asserts nothing. Finding 1 of lesson 4 section 02 is the kind.
- **It gives a human reviewer a head start**: a list of places to look, which is faster to check
  than a diff is to read cold.

## What to keep out of its hands

- **Never the decision to merge.** A bot's approval is a claim, and lesson 4 section 03 showed one
  confident claim in three being wrong. The checks that gate a merge are the ones that are true or
  false: the tests, the linter, the type checker. The bot's comments inform the person who decides.
- **Not its own triage.** A finding the bot is wrong about should be answered on the pull request,
  with the reason, in the same way ana answered finding 3 with a passing test. Silently ignoring
  bot comments teaches a team to ignore all of them, including the right ones.
- **Not more context than it needs.** The job runs with the repository and a key. It should not
  also have the deploy credentials, and the code it sends goes to the provider on every pull
  request, so the policy questions of lesson 3 section 03 apply to it exactly as to an editor.

## Costs worth knowing before turning it on

Every pull request becomes one or more model calls, and a large diff with its surrounding files is
a large input. Lesson 2's arithmetic applies: tokens in per review, times pull requests per day,
times the price. Two settings keep it sane: **a size limit**, above which the bot says the change is
too large to review usefully rather than reviewing a truncated version of it, and **a filter** that
skips generated files, lock files and vendored code, which cost tokens and contain nothing to
review.

The judgement this lesson keeps returning to applies here unchanged. **A review is a list of
hypotheses**, and a hypothesis is worth exactly the test that checks it.
