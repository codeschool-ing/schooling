---
title: A framework, your own code, or both
version: 1
---

After lessons 8 to 12 the course has both: checks written in a few lines each, and two frameworks that
can run them or replace them. The choice is not either-or, and the trade is clear enough to write down.

**A framework gives** a shared vocabulary that other people recognise, dozens of metrics already
written with their prompts, a runner and a report, and a pytest integration. When a team needs
model-graded faithfulness tomorrow, a framework metric is a day of work saved.

**Your own code gives** a definition that fits on one screen, no dependency to pin, and numbers that
cannot change when a library is upgraded. Every metric this course relies on for a decision is one
whose docstring is its whole definition.

**Both** is what most teams end up with, and it works when three rules hold:

1. **Every metric that decides something is measured against labels** before it is trusted, lesson 10's
   kappa, whether it was written in-house or imported.
2. **A framework metric is pinned with the framework**: its version, its class name and the judge model
   are recorded beside every score, because the same name means different arithmetic in different
   releases, as lesson 11 showed across frameworks.
3. **A framework's built-in metric is read before it is run.** Its prompt is in the installed package,
   and reading it says what it will reward.

Lesson 14 uses these metrics to compare two versions of the assistant, and lesson 15 makes the
comparison a test that can fail a build. Both work with the course's own checks or with a framework's,
and both use the sixty labelled replies to say which checks can be believed.
