---
title: How the method goes wrong
version: 1
---

The four steps are simple to state and easy to skip. The ways they get skipped are few, and worth
knowing by name:

| what happens | why it costs | the step it skips |
|---|---|---|
| fixing before seeing the fault | you may fix something that was not broken, and not the thing that was | reproduce |
| trusting the user's diagnosis, "it's the network" | a guess, however confident, is not an observation | reproduce, isolate |
| changing several things at once | the fault goes and nobody knows which change did it | test |
| a check that changes something | the next result no longer means what it seems to | isolate |
| declaring it fixed from your own desk | it works for you and not for them | confirm |
| closing without writing the cause | the same fault is diagnosed again from zero | confirm |

**A fault that comes and goes** is the hardest case, because step 1 fails on the day you look. The
method does not change; the evidence does. Ask for the time of each occurrence, keep a check running
that records when it fails, and compare what was different at those times. Lesson 3 gives the layers to
compare, and lesson 7 says when to hand it on.
