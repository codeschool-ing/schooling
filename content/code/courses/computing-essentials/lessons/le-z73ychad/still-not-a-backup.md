---
title: Still not a backup, and now you can say exactly why
version: 1
---

Lesson eight said that synchronising is not backing up and gave the grid. This lesson has
supplied the mechanism, so the claim can be made precisely.

**A backup is a copy that does not change when the original does. Sync is a mechanism whose
entire purpose is that the copy changes when the original does.** They are not two grades of the
same thing; they are opposites that happen to both produce a second copy.

## The three failures, named

- **A deletion propagates.** In seconds, to every device. The bin holds it for thirty days and
  then it is gone from everywhere at once.
- **Damage propagates.** A file encrypted by ransomware is a file that changed, so it is uploaded
  and pushed out — and a corrupted file is uploaded just as faithfully.
- **The account is a single point.** Suspended, compromised, or closed by somebody who shares it
  with you, and every device loses the same folder together.

None of those is a flaw in the design. All three are the design working exactly as intended.

## What partly rescues it, and how far

**Version history** is the real defence, and all three have it:

| | keeps |
|---|---|
| **OneDrive** | 30 days of versions on personal, more on business, plus a ransomware detection and rollback |
| **Google Drive** | 30 days or 100 versions, whichever comes first, unless a version is marked to keep |
| **iCloud Drive** | 30 days for deleted files; per-file versions only in applications that support it |

**Thirty days is the shape of all of it**, which is the same figure lesson eight called the
minimum worth having. So sync plus version history is genuinely a defence against the first two
rows of that grid — provided somebody notices inside a month.

What it is not a defence against is the third: an account that goes takes its own history with
it.

## The arrangement that is actually right

The same one lesson eight described, with the sync folder taking one of the roles:

- **the working copy** — your machine, with the synced folder on it;
- **the second copy** — the service, which is offsite by construction and covers a stolen or burnt
  machine perfectly;
- **the third copy** — an external drive, unplugged between backups, which is the only one of the
  three that a deletion, a ransomware or a closed account cannot reach.

**Sync earns the middle row and cannot earn the bottom one.** That is the precise version of the
sentence, and it is why this lesson ends where the last two did.

## And one setting worth changing today

Whatever service you use: **find the ransomware or mass-deletion alert and make sure it is on.**
OneDrive has it by default; Drive and iCloud will mail you about unusual activity. It is the only
thing standing between a bad hour and the thirty-day window closing while nobody noticed.
