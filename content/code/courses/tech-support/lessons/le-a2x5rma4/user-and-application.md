---
title: The user and the application
version: 1
---

Two quick checks, one per layer:

```
ana@pc1:~$ sudo -u daniel ls -l /home/daniel/september.csv; ls -ld /srv/shared/reports
-rw-r--r-- 1 daniel root 34 Sep 26 00:38 /home/daniel/september.csv
drwxr-xr-x 2 daniel root 4096 Sep 26 00:38 /srv/shared/reports
ana@pc1:~$ sudo -u daniel bash -c "echo test > /srv/shared/reports/test.txt"
bash: line 1: echo: write error: No space left on device
```

- **User**: the file exists, it is Daniel's, and the folder `reports` is his to write in. He typed the
  right path and has the right to use it. Nothing he did explains the refusal.
- **Application**: a different program, the shell's own `echo`, fails in the same folder with the same
  words. So it is not `cp`, and would not have been his spreadsheet program either.

Both layers are crossed off. What is left starts at the system.
