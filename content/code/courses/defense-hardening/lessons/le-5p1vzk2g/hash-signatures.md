---
title: Hash signatures: exact, and exactly one file
version: 1
---

**A hash signature matches one file and nothing else.** A cryptographic hash such as SHA-256 is a
fingerprint of every byte: two files with the same hash are the same file, and changing a single byte
changes the hash beyond recognition. A signature made from a hash therefore never mistakes a different
file for the one it describes, and never recognises a variant of it either.

Make one for the first sample, with a name of your own:

```
ana@desk:~$ sigtool --sha256 samples/invoice.txt | sed "s/:invoice.txt$/:Jatoba.Lab.Invoice/" > lab.hsb; cat lab.hsb
0cad6ef09fcc2504e6df0bd0c8da112c9ba39df42a87d6b5f86f071e28140e72:34:Jatoba.Lab.Invoice
ana@desk:~$ clamscan --no-summary -d lab.hsb samples/; echo "exit $?"
samples/copy.txt: Jatoba.Lab.Invoice.UNOFFICIAL FOUND
samples/changed.txt: OK
samples/invoice.txt: Jatoba.Lab.Invoice.UNOFFICIAL FOUND
exit 1
```

The original and its exact copy are found. `changed.txt`, which differs by one space, is `OK`. The
scanner is right on all three counts: it was asked whether these files are *that* file, and one of
them is not.

## Why vendors still ship millions of them

Hash signatures are cheap to make, cheap to check and never produce a false positive, so a vendor
adds one for every file its analysts confirm. They are how a scanner recognises the thousands of
copies of one file circulating at once: the attachment in a campaign, the installer on a fake
download page.

Their limit is the other side of the same property. **A hash describes the past.** A file that differs
from every known one in any byte, whether because it was rebuilt, repackaged or simply updated by its
author, matches no hash at all. The defence against that is not a better hash. It is the content
signatures and heuristics of the next two sections, and behind them the EDR of lesson 8, which
watches what a program does instead of what it is.

## Hashes are also how you ask

A hash is the first thing a defender writes down about a suspicious file. It identifies the file
without sharing it, so it can be compared with the organisation's own lists, searched in threat
intelligence feeds and looked up in online services without uploading anything. Lesson 19 is about
those services and why a hash lookup comes before an upload.
