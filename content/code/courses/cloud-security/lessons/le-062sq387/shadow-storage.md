---
title: The storage nobody in IT set up
version: 1
---

**Most company data that leaks through cloud storage does not leak from the company's cloud. It
leaks from an account a person opened with their own e-mail address, on a service the company never
chose, to get a file from one place to another.** That is *shadow storage*, and this lesson is about
it.

The wrong picture is that it is a problem of careless people. The people involved are usually
being helpful: bia wants to send the month's appointments to the clinic's accountant, the
attachment is too large for e-mail, and she has a Google Drive at home. In four minutes the
spreadsheet is uploaded, a link is copied, and the accountant has it. Nothing was hacked and nobody
broke a rule they knew about.

## What leaves with the file

The spreadsheet itself is the small part. What the clinic lost in those four minutes is every
control lesson 9 built around its own storage:

| | the clinic's bucket | bia's personal Drive |
|---|---|---|
| who decides who can read it | the clinic, through policies it can audit | bia, through a share button |
| a record of who read it | what the clinic chose to log (lesson 15) | whatever Google shows bia, and nothing to the clinic |
| what happens when bia leaves | her access is revoked and the file stays | the file leaves with her |
| who can be asked to delete it | the clinic's own administrators | bia, if anybody remembers to ask |
| the scanner of lesson 16 | sees it | does not know it exists |

**The last row is the one that matters most.** Every defence in this course starts from an
inventory, and a file in a personal account is outside every inventory the clinic has. Nobody can
protect, audit or delete what nobody knows about.

## Why it matters more for a clinic

The spreadsheet names a patient on every row, and the `security-fundamentals` course's lesson 17 showed
that the LGPD treats health data as *sensitive* personal data. The clinic is still the controller of
that data wherever a copy ends up. So a copy in a personal account is still the clinic's
responsibility, sitting in a place where the clinic can neither secure it nor prove what happened
to it.

## Three ways it happens

**Personal accounts used for work.** A free OneDrive, Dropbox, Google Drive or iCloud Drive, signed
in with a personal address. The company has no administrator in it and no contract with the
provider.

**Company accounts shared too widely.** The company pays for Microsoft 365 or Google Workspace, and
the file sits in the right tenant, but its sharing setting says *anyone with the link*. The control
exists; the person picked the loosest option. The next section is about those options.

**Cloud storage handed out by link.** The company's own S3 bucket, with a link signed by somebody's
key so that a person outside can download one file. It is the cloud engineer's version of the share
button, and the third section of this lesson builds one in your lab.

The first is outside the company's reach entirely. The other two are inside it, and that is where
the controls in the last section apply.
