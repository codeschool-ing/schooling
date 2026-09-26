---
title: What the system remembers
version: 1
---

The system keeps its own account of what happened, and it does not depend on anyone's memory:

```
ana@pc1:~$ sudo lpstat -W completed -o
pdf-4                   bruno             1024   Sat Sep 26 00:29:21 2026
office-3                ana               1024   Sat Sep 26 00:29:16 2026
pdf-1                   bruno             1024   Sat Sep 26 00:29:14 2026
pdf-2                   bruno             1024   Sat Sep 26 00:29:14 2026
ana@pc1:~$ sudo cat /home/bruno/.cups/lpoptions; sudo stat -c "%y" /home/bruno/.cups/lpoptions
Default pdf
2026-09-26 00:29:13.903412990 -0300
```

- Every job Bruno sent went to `pdf`, and the only job on `office` is the technician's test page.
- His file `~/.cups/lpoptions` holds one line, `Default pdf`, written at **00:29**, the moment the jobs
  started going to the wrong place.

That time is worth more than the setting. It matches what Bruno said when asked what he was doing:
saving a PDF and closing a window. **A time from the logs and a time from the user that agree** turn a
theory into a finding.

`sudo` was needed to see the owners. Without it, `lpstat` shows other people's jobs as `unknown`,
because who printed what is private. Lesson 13 comes back to what a technician can see and what they do
with it.
