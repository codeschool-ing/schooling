---
title: A timeline from the file system
version: 1
---

Every inode carries times, and together they are a **timeline** of the disk: what was created, changed, read and
deleted, and in what order. TSK builds it in two steps. `fls -m` writes every name with its times in a plain
format called a **body file**; `mactime` sorts the body file into a timeline. `-d` separates the fields with
commas, `-y` writes ISO dates, and `-z UTC` puts every time in one zone, as lesson 12 insists:

```
root@soc:~/case# fls -r -m / work.dd > body.txt
root@soc:~/case# mactime -b body.txt -d -y -z UTC 2>/dev/null | grep -E '^Date|exports'
Date,Size,Type,Mode,UID,GID,Meta,File Name
2026-10-08T00:05:18Z,4096,macb,d/drwxr-xr-x,0,0,23,"/exports"
2026-10-08T00:05:18Z,313,macb,r/rrw-r--r--,0,0,24,"/exports/contacts-2026-08.csv (deleted)"
```

The column `Type` holds the letters **m**, **a**, **c** and **b**: the file's content was **m**odified, it was
**a**ccessed, its inode was **c**hanged, and it was **b**orn, created. Here all four happened in the same second,
because the whole disk was made at once and the file deleted moments later; the last line says `(deleted)`.

On a real server the timeline is long, and it is where findings come from: a file read at 02:39 on Thursday, two
minutes before the transfer in lesson 12's timeline, is a candidate for what left. Two cautions go with it.
**Access times are often not updated** on modern Linux, to save writes, so an `a` can be older than the last real
read. And **times can be changed** by anybody with enough access to the server; a timeline is strong when it
agrees with sources the intruder did not control, such as the firewall and the flow records.
