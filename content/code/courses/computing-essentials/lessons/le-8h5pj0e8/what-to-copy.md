---
title: What actually has to be copied, and the six things people forget
version: 1
---

A backup of everything is slow, expensive and rarely finished. A backup of the right things is a
few dozen gigabytes and runs while you make coffee.

## The short answer

**Your home folder, and nothing else.**

Programs reinstall. The operating system reinstalls. Neither of them contains anything that is
yours, and both of them are a download away. A backup that includes `C:\Windows` is spending
most of its time and space on the part that is easiest to replace.

Two exceptions worth naming:

- **A full disk image** is a different tool for a different job — it restores a whole machine as
  it was, including programs and settings, in one step. It is genuinely useful for a work machine
  where reinstalling would cost a day, and it is not a substitute for copying your files, because
  an image is one big object and you cannot pull last month's spreadsheet out of it easily.
- **Virtual machines and large caches** inside the home folder are often worth excluding, because
  they are enormous and they regenerate.

## The six things people forget

Each of these lives outside the folder people think of as *my documents*, and each is discovered
missing at the worst moment.

| | where it is | what losing it costs |
|---|---|---|
| **browser bookmarks and passwords** | the browser's profile folder | years of accumulated links, and every saved login |
| **two-factor codes** | an app on a phone, often not backed up at all | being locked out of everything at once |
| **password manager vault** | usually synced, sometimes only local | the same, and worse |
| **photos on the phone** | the phone | the irreplaceable half of most people's data |
| **program settings** | `AppData`, `~/Library`, `~/.config` | a week of reconfiguring things |
| **e-mail, if it is not webmail** | a local mail file | correspondence, and often the only copy of attachments |

**The second row is the one to act on today.** Losing a phone with an authenticator app and no
recovery codes means proving your identity to a dozen companies, several of which will not
believe you. Every authenticator offers recovery codes; print them and put them somewhere that
is not the phone.

## What not to copy, and why it matters

Excluding things is not fussiness — it is what keeps a backup fast enough to happen daily instead
of monthly:

- **downloads**, unless they are being used as a filing cabinet, which the last lesson argued
  against;
- **caches and temporary folders**, which are large and worthless;
- **anything already versioned somewhere else** — a code repository, a cloud folder with history
  turned on;
- **installers**, which are the definition of re-downloadable.

## And the one that decides everything

**The photographs.** For most people the only truly irreplaceable data is pictures, and most of
them are on a phone rather than on the machine this lesson has been about.

A phone that backs up to a cloud service is one copy in one place, and that is the arrangement
row three of the grid was about. Something automatic, plus a copy pulled onto the computer once
a quarter, is the whole answer — and it is the one piece of housekeeping in this course that
people regret not doing.
