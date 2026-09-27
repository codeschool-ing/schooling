---
title: Three computers, one register
version: 1
---

The same script on three computers, each line appended to one file:

```
ana@host:~$ echo "name,maker,model,serial,cpu,memory,root fs,mac,os" > assets.csv; for m in pc1 pc2 srv1; do ssh $m bash /tmp/inventory.sh >> assets.csv; done; cat assets.csv
name,maker,model,serial,cpu,memory,root fs,mac,os
"pc1","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","961 MiB","6.8G","52:54:00:8c:26:a7","24.04"
"pc2","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","961 MiB","6.8G","52:54:00:8c:e8:f2","24.04"
"srv1","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","1463 MiB","6.8G","52:54:00:db:e3:cb","24.04"
```

Three lines, and **they differ where the machines differ**: `srv1` has 1463 MiB, the others
961, and each has its own MAC. The rest is identical, which is also information: three
computers of the same kind can be replaced, repaired and stocked for together.

Two things went wrong while this lesson was being written, and both are common:

- **A comma inside a value.** The model name has one, and the first version of the script did not quote
  its fields, so a spreadsheet split `(Q35 + ICH9, 2009)` into two columns and shifted every column after
  it by one.
- **A fallback that never fired.** The first version wrote `none` when the serial was empty. It is never
  empty: a machine with no serial says `Not Specified`, and many PCs say *To Be Filled By O.E.M.*, and
  both are text that looks like a serial to a script that only checks for nothing.

The register then needs the people's half beside each line:

| from the machine | from people and paperwork |
|---|---|
| name, maker, model, serial | asset tag, the organisation's own number |
| processor, memory, disk, MAC | who uses it, and where it is |
| operating system and version | bought when, from whom, warranty until when |
| | status: in use, in stock, in repair, retired |
