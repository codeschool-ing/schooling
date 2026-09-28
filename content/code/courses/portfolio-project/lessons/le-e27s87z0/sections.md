---
title: The sections, in order
version: 1
---

Below the first screen a README is a reference, read by the few who go further. loanbook's has six
sections:

```
ana@laptop:~/loanbook$ grep -n '^## ' README.md
10:## What it does
17:## Run it
31:## Deploy
45:## Decisions
60:## Not yet
65:## Licence
```

| section | the question it answers | who needs it |
|---|---|---|
| What it does | what can I do with it? | the hiring manager |
| Run it | how do I see it on my machine? | the technical interviewer |
| Deploy | how does it run on a server? | a reviewer who cares how it runs, and you in six months |
| Decisions | why is it built this way? | everybody who reads this far |
| Not yet | what did you leave out, on purpose? | the reviewer about to ask |
| Licence | may I use it? | lesson 18 |

The order follows the readers of lesson 1: **what** before **how**, and **how to run** before **how it
works**. A reviewer who stops after *What it does* has still learned the project's scope; one who stops
after *Run it* can still try it.

Keep each section to what its question needs. *Run it* is four commands, not a tutorial on installing
Python. *Deploy* names the two files in `deploy/` and the five commands, not a guide to systemd. A
README is a map, and the detail belongs in the files it points to, where it is kept up to date with the
code.
