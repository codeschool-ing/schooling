---
title: How full is the disk, and with what?
version: 1
---

Two different questions, and each has its own command.

```
ana@server:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   14G   25G  36% /
ana@server:~$ du -sh work
2.9M    work
ana@server:~$ du -sh work/*
4.0K    work/clients.csv
8.0K    work/invoices
2.9M    work/reports
PS /home/ana> Get-PSDrive -PSProvider FileSystem | Select-Object Name, Root

Name Root
---- ----
/    /
Temp /tmp/

PS /home/ana> (Get-ChildItem work -Recurse -File | Measure-Object -Property Length -Sum).Sum
3000112
```

- **`df -h`** answers **how full is the disk**, per file system: size, used, available, and the
  percentage. `-h` is lesson 8's *human* sizes.
- **`du -sh`** answers **what is taking the space**, per folder: `work` holds 2.9 MB, and the second
  command shows that nearly all of it is `reports`. `-s` gives one total per argument instead of every
  subfolder.
- PowerShell's **`Get-PSDrive`** lists drives; on Linux there is one, `/`, plus `Temp`. On Windows it
  lists `C:`, `D:` and the rest with their used and free space. **Summing `Length`** over every file is
  PowerShell's `du`: 3000112 bytes, the same 2.9 MB.

The order matters in practice: **`df` first** to see which disk is full, **then `du`** on that disk,
working down into the biggest folder each time.

```sh
Get-Volume                                   # every volume, size and free space
Get-PSDrive C                                # used and free on C:
(Get-ChildItem C:\Users\ana\Documents -Recurse -File | Measure-Object Length -Sum).Sum
```

On a Mac, `df -h` and `du -sh` are the same commands, and *About This Mac > Storage* is the picture of
the same numbers.
