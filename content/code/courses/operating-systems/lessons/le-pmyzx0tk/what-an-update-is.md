---
title: What an update actually contains
version: 1
---

"Install the updates" hides several different things: *security fixes*, *bug fixes*, *new
features*, new *drivers*, and *firmware* for the hardware itself. On a Linux server the first kind
can be read, line by line, in every package's changelog:

```
ana@server:~$ apt-cache policy openssl | head -3
openssl:
  Installed: 3.0.13-0ubuntu3.15
  Candidate: 3.0.13-0ubuntu3.15
ana@server:~$ zcat /usr/share/doc/openssl/changelog.Debian.gz | head -12
openssl (3.0.13-0ubuntu3.15) noble-security; urgency=medium

  * SECURITY UPDATE: Excessive Memory Use Buffering DTLS Records for a Future
    Epoch
    - debian/patches/CVE-2026-54874-1.patch: Avoid full read buffer allocation
      when buffering DTLS records in ssl/record/rec_layer_d1.c,
      ssl/record/record.h, ssl/record/ssl3_record.c.
    - debian/patches/CVE-2026-54874-2.patch: ssl/record: lower the DTLS
      unprocessed_rcds queue limit in ssl/record/rec_layer_d1.c,
      ssl/record/record_local.h, ssl/record/ssl3_record.c.
    - CVE-2026-54874
  * SECURITY UPDATE: Heap Buffer Overflow in CMS Key Unwrapping
ana@server:~$ zcat /usr/share/doc/openssl/changelog.Debian.gz | grep -c 'SECURITY UPDATE'
58
```

- `apt-cache policy` shows the installed version, `3.0.13-0ubuntu3.15`, and the candidate, the same:
  nothing is waiting.
- The **changelog** says what that version changed. Its top entry, from `noble-security`, lists
  *SECURITY UPDATE* after security update, each with a *CVE* number: *Common Vulnerabilities and
  Exposures*, the public identifier of a published flaw.
- 58 such entries in openssl's changelog, which goes back years, for one library. The version
  number of this one barely moved: `3.0.13` stayed, and only the Ubuntu part after it rose.
  That is lesson 6's fixed release: **fixes, not new versions**.

A CVE being public is what makes speed matter. The fix and the description of the flaw are published
together, and anybody can read how the flaw works. **A machine without the fix is not at risk in
theory; it is on a published list.**
