---
title: The system layer
version: 1
---

The message said space, so the first system check is space:

```
ana@pc1:~$ df -h /srv/shared
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   55M     0 100% /srv/shared
ana@pc1:~$ sudo du -sh /srv/shared/*
55M     /srv/shared/logs
16K     /srv/shared/lost+found
4.0K    /srv/shared/reports
ana@pc1:~$ sudo tail -n 2 /srv/shared/logs/export.log; echo
2026-09-26 export: retrying connection to the sales database
2026-0
```

- `df -h` answers for the file system that holds `/srv/shared`: **100% used, 0 available**.
  The message was literal.
- `du -sh` says where the space went: **`logs` holds 55M**, and Daniel's `reports` holds almost
  nothing.
- The last lines of `export.log` show what was writing it: the same line, a program retrying a
  connection to the sales database, over and over. The very last line stops in the middle, at `2026-0`:
  the program was cut off mid-line when the disk filled.

That is the cause: **a log that grew until the shared disk was full**, and every write after that
failed, Daniel's report included. The report was never the problem; it was the first thing somebody
noticed.
