---
title: Integrity you can check
version: 1
---

**Integrity is the property people forget, because a changed file looks exactly like a correct
one.** A leaked customer list makes the news. A price that drifted from R$ 45.90 to R$ 4.59 sits
in the catalogue looking ordinary until somebody notices the shop has been selling at a loss for
a week.

So the question integrity asks is not only "can somebody change this?" but "**would we know if
they had?**" This section answers the second half on a real file.

You do not need to type any of what follows. Every transcript in this course was recorded in the
course's lab, a small copy of the bookshop's network built on one Linux computer, and the prose
says what each command does. A line beginning `ana@laptop:~$` is ana, who runs the shop's IT,
typing on the office laptop; everything under it is what the computer answered.

Here is the price list, and a fingerprint of it:

```
ana@laptop:~$ cat prices.csv
isbn,title,price_cents
9788535914849,Dom Casmurro,4590
9788525432186,Vidas Secas,3990
9788520932964,Grande Sertao: Veredas,8990
ana@laptop:~$ sha256sum prices.csv > prices.sha256
ana@laptop:~$ cat prices.sha256
6fff9e30ac0f27672ff735d4a415423a48b67ae5db16e473f1e3bf341064c11d  prices.csv
ana@laptop:~$ sha256sum -c prices.sha256
prices.csv: OK
```

`sha256sum` reads the whole file and computes a **SHA-256 hash**: 64 hexadecimal characters that
depend on every byte of the input. The same file always gives the same hash, and any change at
all gives a different one. ana saved the hash in `prices.sha256`, and `sha256sum -c` reads that
file, computes the hash again and compares. `OK` means the file is byte for byte what it was.

Now one character changes. In real life this would be a mistaken edit, a buggy import or
somebody tampering; here it is a command that removes a zero:

```
ana@laptop:~$ sed -i 's/,4590/,459/' prices.csv
ana@laptop:~$ cat prices.csv
isbn,title,price_cents
9788535914849,Dom Casmurro,459
9788525432186,Vidas Secas,3990
9788520932964,Grande Sertao: Veredas,8990
ana@laptop:~$ sha256sum -c prices.sha256
prices.csv: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@laptop:~$ sha256sum prices.csv
350f6313295d12dcfa2bd78f2908d1becd87f2360fccf9e6ae3fc7ffc2f2880a  prices.csv
```

**One character, and the check says `FAILED`.** The new hash, `350f6313…`, has nothing
visible in common with the old one, `6fff9e30…`. That is a designed property of a good hash
function: a small change in the input scrambles the whole output, so nobody can make a "nearly
the same" file that passes. `cryptography` lesson 4 explains how that is achieved and why MD5 and
SHA-1 no longer qualify.

Two limits matter as much as the result:

- **A hash says THAT something changed, never WHAT or WHO.** The check above does not point at
  line 2, and it does not say the change was malicious. Finding out is a separate job.
- **The kept fingerprint has to be safer than the file.** If whoever can edit `prices.csv` can also
  edit `prices.sha256`, they change both and the check passes. Real systems keep the reference
  somewhere the attacker cannot write, or sign it with a key the attacker does not have, which is
  what `cryptography` lesson 6 is about.

The same idea, scaled up, is behind a lot of everyday security. A package manager checks the hash
of every download before installing it. A backup tool records hashes so a restore can prove it
brought back what was saved, which lesson 12 uses. File-integrity monitors keep hashes of a
server's programs and raise an alert when one changes.
