---
title: Autopsy
version: 1
---

**Autopsy** is a free, open-source graphical program built on The Sleuth Kit. Everything this lesson did on the
command line, it does through windows, with a case file around it. **It was not run for this lesson**: it is a
large desktop application, and on Linux it installs as a separate download rather than an Ubuntu package. What it
adds over the commands is worth knowing, because most forensic reports cite it:

| it does | the command line equivalent in this lesson |
|---|---|
| opens an image, raw or E01, into a **case** with the examiner's name | `fsstat`, and lesson 16's custody record |
| a file tree, with deleted files marked | `fls -r`, the asterisk |
| file content in text, hex and image views | `icat`, and `blkcat` with `xxd` |
| a **timeline** view, filterable by date and type | `fls -m` and `mactime` |
| **keyword search** over the whole image, free space included | `blkls` and `grep`, done by hand |
| **hash sets**: marks files known to be harmless, or known to be bad | `sha256sum` and a list |
| tags and a **report** of everything tagged | the incident record, written by hand |

The relationship is the important part. Autopsy makes the work faster and easier to show to somebody else; it does
not find anything the underlying tools cannot. When a finding matters, an examiner who knows the commands can check
it without the interface, and say exactly which inode and which block it came from.
