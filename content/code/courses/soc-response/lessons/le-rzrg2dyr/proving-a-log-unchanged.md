---
title: Proving a log has not changed
version: 1
---

A copy elsewhere keeps a log available. It does not, by itself, answer the question somebody will ask
months later: **how do you know this file is the one you collected?** The answer is a hash, written down
at the moment of collection and kept apart from the file.

A **cryptographic hash** such as SHA-256 turns any file into a 64-character fingerprint. Change one byte
anywhere and the fingerprint changes completely, and nobody knows how to construct a different file with
the same fingerprint. So the routine at the end of each day is: copy the day's file, hash it, and store the
hash where the people who handle the file do not:

```
root@soc:~# cp /var/log/remote/gw.log gw-day1.log
root@soc:~# sha256sum gw-day1.log | tee gw-day1.log.sha256
5ed00f936671242652748f410fa3a6f957fd2cce22df3ae4273707298885a3ea  gw-day1.log
root@soc:~# sha256sum -c gw-day1.log.sha256
gw-day1.log: OK
root@soc:~# sed -i 's/203.0.113.66/198.51.100.99/' gw-day1.log
root@soc:~# sha256sum -c gw-day1.log.sha256
gw-day1.log: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
```

One address changed in the copy, `203.0.113.66` to `198.51.100.99`, and the check fails. It does not say
*what* changed, only that something did, which is what it is for: an analyst who sees `FAILED` stops
relying on that copy and goes back to one whose hash matches.

A single hash covers a closed file. A log that is still growing needs something finer, and the classic
answer is a **hash chain**: each line's hash covers that line *and the hash of the line before*. Here it is,
small enough to read:

```schooling-example
{"language": "bash", "file": "chain.sh", "parts": [{"code": "#!/bin/bash\n# chain.sh FILE: one hash per line, each one covering every line before it\nprev=$(printf 'start' | sha256sum | cut -c1-16)", "note": "The chain starts from a fixed value, so two people running the script on the same file get the same hashes."}, {"code": "while IFS= read -r line; do\n  prev=$(printf '%s%s' \"$prev\" \"$line\" | sha256sum | cut -c1-16)", "note": "Each new hash is taken over the previous hash and the line together, so a line's hash depends on every line before it."}, {"code": "  printf '%s  ...%s\\n' \"$prev\" \"${line: -44}\"\ndone < \"$1\"", "note": "Print the hash beside the end of the line, which is where these lines differ from one another."}]}
```

Run it on the day's copy, then delete the second line and run it again:

```
root@soc:~# bash chain.sh gw-day1.log
f32a8cbd8f4539cc  ...: Server listening on 198.51.100.22 port 22.
7267c958d4ea37ac  ...alid user admin from 203.0.113.66 port 32906
5fc413ac19cc05fa  ...user admin 203.0.113.66 port 32906 [preauth]
root@soc:~# sed -i '2d' gw-day1.log
root@soc:~# bash chain.sh gw-day1.log
f32a8cbd8f4539cc  ...: Server listening on 198.51.100.22 port 22.
dcdfd43755d0bc4a  ...user admin 203.0.113.66 port 32906 [preauth]
```

The first hash, `f32a8cbd8f4539cc`, is the same both times because nothing before it changed. **Every hash
after the removed line is different**, so anybody holding the original chain, or only its last value, sees
not just that something changed but from which line on.

Real systems build the same idea in. `journald` has **Forward Secure Sealing** (`journalctl --setup-keys`
and `journalctl --verify`, not run here), which seals the journal at intervals. Object stores offer
**write once, read many** locks, so that a bucket of logs cannot be altered, even by its own administrator,
until the retention period ends. And on a single Linux machine, `chattr +a` makes a file **append-only**, so
that new lines can be added and existing ones cannot be rewritten without first removing the attribute.
