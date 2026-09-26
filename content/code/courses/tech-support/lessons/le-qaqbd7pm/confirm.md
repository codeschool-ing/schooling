---
title: Confirm: the same check, from the user’s side
version: 1
---

The last step repeats the first, on the same computer, with the same command:

```
ana@pc1:~$ getent hosts intranet; curl -sS -m 10 http://intranet/
10.30.0.31      intranet
intranet: welcome
```

`pc1` now finds `10.30.0.31` and the page answers. Confirming has three parts, and the command is only the
first:

- **The check from step 1 passes.** Not a different, easier check: the same one.
- **The user sees it.** Carla opens the intranet in her own browser. The fault was hers, and so is the
  confirmation; a ticket closed without it is often reopened the next morning.
- **The cause is written down**: which line, what it said, and why it was wrong. The same stale line
  may be on other computers set up at the same time, and the ticket is where the next technician will
  look, lesson 5.
