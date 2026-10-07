---
title: The raw files stay raw
version: 1
---

Every lesson in this course read from `raw/` and none of them wrote to it. That was not politeness.
**The raw files are the only evidence of what arrived**, and a cleaning that edits them destroys
the thing it would need to be checked against. Lesson 1 set the lab up so that this rule is
enforced rather than remembered:

```
ana@lab:~/clean$ ls -ld raw; ls -l raw | head -4
dr-xr-xr-x 2 ana ana 4096 Oct  7 01:52 raw
total 6908
-r--r--r-- 1 ana ana  244696 Oct  7 01:52 customers.csv
-r--r--r-- 1 ana ana     286 Oct  7 01:52 fx_rates_2025.csv
-r--r--r-- 1 ana ana    3659 Oct  7 01:52 invoices.csv
ana@lab:~/clean$ touch raw/notes.txt
touch: cannot touch 'raw/notes.txt': Permission denied
ana@lab:~/clean$ sed -i 's/Pepino/Pepino japonês/' raw/products.csv
sed: couldn't open temporary file raw/sedCSmpNw: Permission denied
```

The directory and every file in it are read-only, so a stray `touch` or an in-place `sed` fails
instead of quietly changing the data. That protection has a limit worth stating: ana owns the
files, so she could make them writable again. **Read-only guards against accidents, not against
intent**, and the next step is what catches the rest.

A **checksum** is a fingerprint of a file's bytes. Change one character anywhere and the SHA-256
fingerprint changes completely. Recording the fingerprints of the raw files once, when they arrive,
makes any later change detectable:

```
ana@lab:~/clean$ sha256sum raw/*.csv > raw.sha256 && head -3 raw.sha256
8a594c4c04516e4398bebea1c3d13357730d214f5ce8b7e14927d717217860c1  raw/customers.csv
828ced3123e1715e6b6df68071cd4461ba91e019c4f0f5194760b43c759f8302  raw/fx_rates_2025.csv
351f51e69a37b56975b307f8c8e8de040751857e947bc2f1aad1a5a7591c8351  raw/invoices.csv
ana@lab:~/clean$ sha256sum --check --quiet raw.sha256 && echo all raw files match
all raw files match
```

`raw.sha256` is small, readable and goes under version control with the code. Before any rerun,
`sha256sum --check` says whether the inputs are still the ones the results were built from. If a
file was replaced, re-exported or edited, the check names it, and the results built on the old one
are known to be out of date rather than silently wrong.

The same idea extends to anything else the analysis depends on from outside: the reference files of
lesson 14, in `ref/`, belong in the manifest too, with `sha256sum raw/*.csv ref/*.csv`.
