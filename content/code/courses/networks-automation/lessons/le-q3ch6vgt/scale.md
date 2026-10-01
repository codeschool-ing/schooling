---
title: The arithmetic of scale
version: 1
---

The script took this long for three routers:

```
real	0m3.539s
user	0m0.238s
sys	0m0.137s
```

`real` is the time on the wall clock, from the moment the command started until the prompt came
back: **3.539 seconds for three routers**, a little over a second each, most of it spent logging
in and waiting for prompts. The lab's routers are namespaces on one computer, so a real network
adds its own round trips to every login. The shape of the sum does not change.

Now put an assumption beside it, and label it as one: **a person who takes two minutes per router**
to open a session, type the line, check it and save. That is a guess, not a measurement, and the
argument survives any reasonable guess:

| routers | by hand, at 2 minutes each | the script, in sequence |
|---|---|---|
| 3 | 6 minutes | seconds |
| 100 | 3 hours 20 minutes | about 2 minutes |
| 1,000 | 33 hours | about 20 minutes |

The script's column is an extrapolation of the second or so per router measured above, so read it
as a size and not as a promise. **Two things grow with the number of routers when the work is
manual, and only one of them is time.** The other is the number of chances to make the mistakes
of the previous section: a thousand sessions are a thousand opportunities to type `192.0.12.0`.

A script also does not have to work in sequence. Nornir, in lesson 8, runs the same task against
many devices at once, which turns "about 2 minutes" into little more than the time of the slowest router.

**Scale is also why a change needs a plan for going wrong.** The twenty minutes that deliver a
correct change to a thousand routers deliver a wrong one just as fast. Lesson 13 is about trying a
change on one device before the rest.
