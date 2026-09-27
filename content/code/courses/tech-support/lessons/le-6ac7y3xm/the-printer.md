---
title: The printer keeps a copy
version: 1
---

Elisa printed her letter earlier. The print queue's history, lesson 2's `lpstat`, looks like this to the
technician:

```
ana@pc1:~$ lpstat -W completed -o
office-1                unknown           1024   Sat Sep 26 02:14:18 2026
ana@pc1:~$ sudo lpstat -W completed -o
office-1                elisa             1024   Sat Sep 26 02:14:18 2026
```

Without `sudo`, the job belongs to `unknown`: **CUPS hides from each user who printed what**, unless the
job is theirs. That is its default, the `JobPrivateValues default` line in `/etc/cups/cupsd.conf`. With
`sudo`, the name is there.

The history is not all the print server keeps:

```
ana@pc1:~$ sudo ls -l /var/spool/cups
total 12
-rw------- 1 root lp 1107 Sep 26 02:14 c00001
-rw-r----- 1 root lp   14 Sep 26 02:14 d00001-001
drwxrwx--T 2 root lp 4096 Jun 11 11:49 tmp
ana@pc1:~$ sudo cmp /var/spool/cups/d00001-001 /home/elisa/letter-to-doctor.txt && echo identical
identical
```

`d00001-001` is the document itself, kept in the spool after the job finished. How long it stays is a
setting of the print server. `cmp` compares two files and prints nothing when they are the same, so
`identical` says the copy is Elisa's letter, byte for byte, **and nobody had to read it to find out**.
That is the habit to take from this capture: when a job needs to know whether something is there, find
out without reading it.

A shared office printer is usually a server like this one. Everything the office prints passes through
it, and whoever administers it can reach all of it.
