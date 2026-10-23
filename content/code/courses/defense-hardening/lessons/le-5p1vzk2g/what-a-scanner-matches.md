---
title: What a scanner actually compares
version: 1
---

**An antivirus scanner compares files with descriptions of files somebody has already judged.** The
description is a **signature**, and the scanner is only as good as its list of them. The common
picture is of a program that recognises danger. What it recognises is resemblance to something
already seen, which is both why it works so well against the common case and why the last section
of this lesson exists.

Start the lab with `sudo bash hostlab.sh up desk`. The lab installed **ClamAV**, the open-source
scanner, on every machine. Ask it to scan a file:

```
ana@desk:~$ clamscan --no-summary eicar.txt; echo "exit $?"
LibClamAV Error: cli_loaddbdir: No supported database files found in /var/lib/clamav
ERROR: Can't open file or directory
exit 2
ana@desk:~$ ls /var/lib/clamav
```

It refuses, and the reason is the point of this section: **without signatures, a scanner has
nothing to compare with.** ClamAV's signatures come from Cisco's servers through `freshclam`, the
updater, which runs as a service and fetches new ones several times a day. The lab cannot reach those
servers, so `/var/lib/clamav` is empty, and **downloading the official database was not run for this
course.** On a machine with internet access, `sudo systemctl enable --now clamav-freshclam` fills the
directory with several hundred megabytes of signatures within minutes.

That gap turns out to be useful. Every signature in this lesson is one you write, which is the best
way to see what a signature is.

## A file made to be detected

The **EICAR test file** is 68 printable characters that every antivirus vendor agreed, in the 1990s,
to detect as if it were a virus. It does nothing; it exists so that a scanner, a mail filter or a
quarantine can be tested without handling anything dangerous. Any scanner with a current database
reports it. Here it is, and a signature for it made by `sigtool`, ClamAV's own tool:

```
ana@desk:~$ cat eicar.txt; echo; wc -c eicar.txt
X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
68 eicar.txt
ana@desk:~$ sigtool --sha256 eicar.txt > lab.hsb; cat lab.hsb
275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f:68:eicar.txt
ana@desk:~$ clamscan --no-summary -d lab.hsb eicar.txt; echo "exit $?"
eicar.txt: eicar.txt.UNOFFICIAL FOUND
exit 1
```

The signature is three fields: the file's SHA-256 hash, its size in bytes, and a name. `-d` tells
`clamscan` to use that one file as its database, and it reports the match with the name and
`.UNOFFICIAL`, ClamAV's mark for a signature it did not ship. **Exit status 1 means "found"**, 0 means
clean and 2 means the scan itself failed, as it did above; scripts and schedules read that number.

## Stand-ins for the rest of the lesson

Nothing in this course handles real malware, and nothing needs to. The rest of the lesson uses three
short text files that stand for "a file the firm has decided is bad", one of them a copy of another
and one differing by a single space:

```
ana@desk:~$ mkdir samples && printf "JATOBA-LAB-SAMPLE invoice 2026-10\n" > samples/invoice.txt && cp samples/invoice.txt samples/copy.txt && printf "JATOBA-LAB-SAMPLE invoice 2026-10 \n" > samples/changed.txt && sha256sum samples/*
ea62d09edf0db80993d227b7b6f8d0124de06b98686acbbf0c69e74a8968c1e9  samples/changed.txt
0cad6ef09fcc2504e6df0bd0c8da112c9ba39df42a87d6b5f86f071e28140e72  samples/copy.txt
0cad6ef09fcc2504e6df0bd0c8da112c9ba39df42a87d6b5f86f071e28140e72  samples/invoice.txt
```

The two identical files have identical hashes. The third, one character longer, has a completely
different one, and the next section shows what that does to a signature.
