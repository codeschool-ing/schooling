---
title: Choosing a version, and checking the download
version: 1
---

Lesson 6 covers the families of Linux distributions properly. For this lesson the choice is made:
*Ubuntu*, the most common distribution on both office desktops and small servers, and specifically an
*LTS* release.

**LTS** means *long-term support*. Ubuntu publishes a new version every six months, and every two years,
in April, one of them is LTS: it receives security updates for *five years* as standard, and longer
with Canonical's paid *Ubuntu Pro*. The version number is the year and month: **24.04** is April 2024.
For a machine that has to keep working without anybody thinking about it, like the office server, only
an LTS makes sense.

There are two downloads: *Desktop*, with the graphical interface, and *Server*, without one. Both are
ISO files of a few gigabytes (lesson 2).

## Check what you downloaded

A download can arrive damaged, or, much more rarely and much worse, it can come from a mirror that
somebody tampered with. Every distribution publishes a **checksum** for each file: a long number
computed from its exact contents, in a file usually called `SHA256SUMS`. If one byte of the download
differs, the number is completely different.

Here is the check on a small stand-in file, with its published sums beside it:

```
ana@server:~/downloads$ cat SHA256SUMS
5af7b95208fdcff454bab3f5eddf567a688a3796c703d4fef91072e38645c062  download.img
ana@server:~/downloads$ sha256sum -c SHA256SUMS
download.img: OK
ana@server:~/downloads$ sha256sum -c SHA256SUMS
download.img: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
```

`OK` means the file is byte for byte what the publisher made. Then one byte of it was changed, and the
same check says `FAILED`. A failed checksum means **download it again**, never "it is probably fine".

On Windows the same number comes from `Get-FileHash` in PowerShell, and on macOS from
`shasum -a 256`. To be sure the `SHA256SUMS` file itself is genuine, distributions also sign it with a
cryptographic key, and checking that signature is the thorough version of this step.
