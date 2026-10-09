---
title: Custody of the image
version: 1
---

Lesson 3 introduced the **chain of custody** for logs: a record of who held a piece of evidence, from when to
when, and what they did with it. An image is the same, with more at stake: it may be what a court, an insurer
or the ANPD is shown. For the image just made, the record reads like this:

| field | value |
|---|---|
| case | INC-2026-014 |
| item | 001, `files` data disk |
| acquired by | diego, witnessed by ana |
| when | the date and time of the acquisition, with the time zone |
| how | read-only loop device; `dd` (raw) and `ewfacquire` (E01, EnCase 6) |
| SHA-256 | the hash from the acquisition output, the same for the device, the raw image and the E01 |
| MD5 | the one stored in the E01 |
| stored | where the original and the image are kept, and who can open that place |
| transfers | every later hand-over: from whom, to whom, when, why, and the hash checked at each one |

The rules that make the record worth having are few:

- **Two copies of the image, kept apart**, and neither of them opened. Analysis uses a **third**, the working
  copy, checked against the same hash before work starts.
- **The hash is checked at every hand-over**, and the check is written down. A transfer with no hash check is a
  gap in the chain.
- **The original is sealed and stored**, if it can be. On Thursday the server stays in service, so the original
  is the image made from it, and the record says so.

A wrong entry is corrected by a new entry that says what was wrong, never by editing the old one: the same rule as
the append-only audit log, for the same reason. And the record starts **at the moment of acquisition**. Written
the next day from memory, it is the first thing a lawyer for the other side asks about.
