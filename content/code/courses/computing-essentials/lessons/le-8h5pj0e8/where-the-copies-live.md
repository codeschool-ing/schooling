---
title: Where the copies live, and what each place is actually good at
version: 1
---

Three kinds of place, and they are not competing. The rule asks for two of them, and which two
depends on what you are willing to do by hand.

| | what it is good at | what it is bad at |
|---|---|---|
| **an external drive** | fast, cheap per gigabyte, entirely yours, works with no connection | it is in the same room, and it needs a person |
| **a sync service** | automatic, offsite, on every device, free at small sizes | it copies damage, and it is not designed to be a backup |
| **a backup service** | automatic, offsite, versioned, large | it costs monthly, and a full restore takes days over a domestic connection |

**The cheapest arrangement that satisfies the rule** is an external drive you connect weekly plus
a backup service running nightly. The drive is the fast restore; the service is the one that
survives the building.

## The external drive, in practice

- **Buy a plain disk rather than an SSD.** For a backup you want capacity per unit of money, and
  the speed difference matters once a week for twenty minutes.
- **Two drives, alternating**, is the version of this that people who have lost something use.
  One in the drawer, one at a relative's house, swapped monthly. That is a complete offsite copy
  for the price of a second drive and no subscription.
- **Encrypt it.** A backup drive is a copy of everything you own in a form somebody can carry
  away. Both Windows and macOS encrypt an external drive with one checkbox.
- **Label it with the date it was bought.** Drives wear out and nobody remembers.

## The cloud, honestly

A **sync service** and a **backup service** are different products that both say "cloud", and the
difference is the one this lesson has been making:

- A sync service keeps the current state in two places. Its version history is a rescue, not a
  design.
- A backup service keeps the history and is built around restoring. It does not put the files on
  your desktop and it is not for working from.

Use both if you like; do not count them as two copies of different kinds, because if the sync
folder is what the backup service is copying, a corruption travels through both.

## Encryption, and the one question to ask

Anything you send off your own machine should be encrypted, and there are two kinds of promise:

- **Encrypted in transit and at rest** — the service can read your files and promises not to.
  Every mainstream sync service is this.
- **End to end**, or *zero knowledge* — the service holds only ciphertext and cannot read
  anything. The provider cannot help you if you lose the key, which is the trade.

**For a backup, take end to end and write the key down on paper.** For a sync folder you work
from daily, the convenience of the other kind is usually worth it — as long as you know which
one you have.

## A warning about "unlimited"

Unlimited plans have fair-use limits that are not published, and accounts holding many terabytes
get letters. If the data matters, a plan with a number on it is a plan whose limit you already
know.
