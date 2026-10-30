---
title: The directory Google Cloud trusts
version: 1
---

**Google Cloud does not keep a list of people.** Every `user:` and `group:` of lesson 5 lives in a
directory somewhere else, and Google Cloud trusts it. For a company, that directory is one of two
products from the same family:

| | what it is | what it costs |
|---|---|---|
| **Cloud Identity Free** | accounts, groups and sign-in, for people who need Google Cloud and nothing else | nothing, up to a number of users Google sets |
| **Cloud Identity Premium** | the same, plus device management, advanced security reports and more controls | per user per month |
| **Google Workspace** | Cloud Identity **plus** Gmail, Drive, Meet and the rest | per user per month, by edition |

All three give a company the same thing as far as Google Cloud is concerned: **accounts under its own
domain**, such as `ana@example.com`, that the company creates, suspends and deletes, and that belong to
the company rather than to the people using them. A company already on Workspace has a directory; a
company that writes code and reads email elsewhere usually adds Cloud Identity Free for exactly this.

## Verifying the domain, and the organisation that appears

Signing up for either starts with **proving the company owns its domain**, by adding a TXT record that
Google gives you to the domain's DNS. Lesson 19 is about DNS records; here, the record is what turns
`example.com` from a string into something Google will let one customer claim. When the domain is
verified, **Google creates the organisation node of lesson 2 for it**, `organizations/123456789012` in this
course's story, and from then on projects can live under it.

The first account is a **super administrator** of the directory. It is a different power from anything in
IAM, and a greater one: a super administrator can reset any user's password, including the password of
whoever is Owner of production. **Treat the super administrator accounts as the keys to the whole
estate**: two of them, used only for directory work, each with a hardware security key as its second
factor, and never used for day-to-day Google Cloud work.

## The account is the person's, the access is the directory's

This arrangement is what makes **offboarding** a single act. When somebody leaves, the directory suspends
their account, and at that moment every Google Cloud role granted to `user:` that address, or to a group
they were in, stops working, in every project, without anybody reading an IAM policy. When a contractor
joins for three months, the directory creates the account and adds it to `planner-devs`, and the IAM
policies stay as they were.

It is also why **personal Gmail accounts should not hold roles in a company's estate**. Nobody at the
company can suspend `ana.personal@gmail.com`; when Ana leaves, the account goes with her, and so does every
grant somebody forgot to remove. Lesson 5's domain-restriction policy is the guardrail that makes this a
rule rather than a hope.

Nothing in this section ran: the directory is a Google service with no emulator and no free sandbox
without an account. The next section writes the planner's groups in Terraform, which the Cloud Identity
API would create.
