---
title: Did it arrive intact?
version: 1
---

The same size is a good sign and not a proof. A **checksum** is: `sha256sum` reads every byte of a
file and prints a 64-character fingerprint that changes completely if a single bit does. Run on both
ends:

```
ana@laptop:~$ sha256sum licences.tar.gz
77dba05f431399c924a90ae73166f79b8f3a9d684073ef34f10aaed8d2d37d84  licences.tar.gz
ana@laptop:~$ ssh office sha256sum licences.tar.gz
77dba05f431399c924a90ae73166f79b8f3a9d684073ef34f10aaed8d2d37d84  licences.tar.gz
```

`77dba05f4313…` on both, so the file on the server is byte for byte the one on the laptop. The
second command ran `sha256sum` on the server through `ssh`, without opening a session there.

Worth doing for anything that matters: a backup before it is relied on, a large file after an unsteady
connection, an installer downloaded for twenty PCs. Software vendors publish the SHA-256 of their
downloads for exactly this, and comparing it takes a few seconds.
