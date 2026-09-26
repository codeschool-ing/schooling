---
title: The symptom, in the system’s words
version: 1
---

Daniel, in finance, writes: *I can't save the September report to the shared folder.* The shared folder
is `/srv/shared`, and his report is `september.csv`. Reproduced as Daniel, lesson 2:

```
ana@pc1:~$ sudo -u daniel cp /home/daniel/september.csv /srv/shared/reports/
cp: error writing '/srv/shared/reports/september.csv': No space left on device
```

The message is worth reading slowly. **`No space left on device`** is not the copy program's opinion;
it is the operating system's answer, passed on word for word. A message often names its own layer, and
this one points at the system. It is still a clue rather than a finding, so the layers above it are
checked first, quickly.
