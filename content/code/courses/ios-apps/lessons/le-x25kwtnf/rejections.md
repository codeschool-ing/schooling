---
title: A rejection, and what to do with it
version: 1
---

**A rejection is a message in App Store Connect that names a guideline, says what the reviewer saw,
and leaves the build where it was.** It is not a judgement on you and it is rarely final. Apple's App
Review page, read on 30 October 2026, says that when a submission does not pass "details are
provided, including any specific App Review Guidelines that your submission didn't follow", and that
you "can correspond with App Review to resolve the issues before resubmitting". Nothing here was run;
no build of the planner was submitted.

## Read it in three parts

1. **The guideline number.** It says which part of section 06's document the reviewer applied, and the
   text of that guideline is what your fix has to satisfy, not the reviewer's sentence alone.
2. **What they saw.** A screenshot, a step, a device and an iOS version. Reproduce it on that version
   before changing anything; a crash on a device you did not test is the commonest 2.1 rejection.
3. **What they ask for.** Sometimes it is information, a demo account or an explanation of a feature,
   and the answer is a reply, not a new build.

## Four the planner could get, and the answer to each

| what the message says | guideline | what to do |
|---|---|---|
| the app crashed on launch on the reviewer's iPad | 2.1 | an iPhone app can be reviewed on an iPad; test it there, reproduce the crash and fix it |
| sign-in required and no demo account given | 2.1 | add a demo account in *App Review Information*, or let the planner work without an account |
| the camera prompt does not explain the use | 5.1.1 | rewrite the usage string from lesson 18 section 02, and resubmit |
| accounts can be created but not deleted | 5.1.1(v) | add account deletion inside the app |

**Reply before you resubmit when the reviewer misunderstood.** If the app does something the reviewer
did not find, a sentence explaining where it is, in the reply thread, is faster than a new build and
keeps the record of why. If you believe the decision itself is wrong, section 06's appeal is the next
step, once.

## Afterwards

An approved build waits for release: at once, on a date, or by hand, as you chose when submitting. A
**phased release** spreads an update over several days and can be paused, which is the subject of
`mobile-delivery` lesson 8. And every rejection is worth a line in the project's notes: the same
guideline tends to catch the same team twice.
