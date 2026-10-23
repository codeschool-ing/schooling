---
title: SaaS, where what is left is people and data
version: 1
---

**On SaaS there is no machine, no runtime and no code of yours, and what remains is the part breaches
are made of: who has an account, what they may share, which other products may reach in, and how long
the data stays.** Nothing in this section was run. A SaaS product has no imitation in this lab, and
the controls below are taught from the documentation of the products named.

The wrong picture is that buying SaaS buys the vendor's security as well. It buys the vendor's
**platform** security, which is real and is described in the vendor's reports, as lesson 2 showed. The
settings inside your tenant are as much yours as a bucket policy, and they are often switched to the
permissive end when the tenant is created, because that is what makes a trial work.

## Four items, and the setting behind each

| item | the question | where it lives, in two common products |
|---|---|---|
| **accounts** | does everybody sign in through the company's identity provider, with MFA, and does leaving the company end the account? | Microsoft 365 through Microsoft Entra ID; Google Workspace through its Admin console, or an external identity provider over SAML |
| **sharing** | may a file be shared outside the company, or with "anyone with the link"? | SharePoint and OneDrive sharing settings; Drive sharing settings in the Admin console |
| **integrations** | may a user grant a third-party application access to their mail or files, by clicking "allow"? | Entra ID's user consent settings; API controls for third-party apps in Google Workspace |
| **retention and audit** | how long are records kept, can they be exported and deleted, and is there a log of who read what? | retention policies and the audit log, whose detail depends on the licence |

Each row is one decision in an administration screen, and each has a common failure:

- **accounts**: a person who left still signs in, because the SaaS account was created by hand and never
  tied to the directory. dani's account in lesson 6 is the same failure in AWS;
- **sharing**: a folder shared with "anyone with the link" for one meeting and never unshared. Lesson
  10 is about this one;
- **integrations**: a calendar add-on a receptionist approved in 2022, which still holds permission to
  read every message in her mailbox;
- **audit**: the record of who read a patient's file exists only on a licence the clinic did not buy,
  which is a question to settle before the incident rather than after. The 2023 case of lesson 2 was
  found in exactly such a record.

## What the contract adds

On SaaS the vendor holds your data, so two documents belong to your list as much as any setting. The
**data processing agreement** makes the vendor what the LGPD calls an *operador*, someone who processes
personal data on the clinic's behalf and under its instructions, and says what it may do with it. The
**list of subprocessors** names the other companies that touch the data, and the countries they are
in, which lesson 17 returns to.

## Asking the questions

Nothing about this list needs a command line. It needs the administration screen, a person who knows
the answers, and the same habit as the last two sections: **read the setting back and keep the
evidence**. A screenshot of the sharing settings, dated, is to SaaS what the `describe-security-groups`
transcript was to IaaS. Products that collect those settings across many SaaS tenants are sold as
*SaaS security posture management* (SSPM), the SaaS relative of lesson 16's subject.
