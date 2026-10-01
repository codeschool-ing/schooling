---
title: The account owner, and why it stays in a drawer
version: 1
---

Every cloud account begins with one identity: the e-mail address and password that opened it. AWS
calls it the **root user**. It can do everything in the account, and no permission policy inside the
account can limit it, because policies are how the account limits its identities and the root user
is the one they were not written for. Everything this lesson builds is a set of brakes, and root is
the one identity with none fitted.

## "I am the only one here, so I will use root"

That is the common picture, and it is reasonable on the first afternoon: one person, one account,
one password. It goes wrong in three ways that have nothing to do with how many people there are.

**A mistake has no ceiling.** Every session opened as root is a session in which a wrong click, a
script run in the wrong terminal or a stolen browser cookie can do anything at all, including
closing the account. An identity with administrator rights is almost as strong, but it can be
limited, watched and removed; root can only be protected.

**The log cannot tell people apart.** The audit log (the last reading section of this lesson) records
the identity that made each call. The day a second person joins and is handed the same password, every
entry reads "root", and the question "who deleted the database on Tuesday" has no answer the log can
give.

**The owner is also the way back in.** A few tasks need the root user and nothing else. Closing the
account is one; another is removing a bucket policy that was written to deny everybody and has locked
out every identity, administrators included. If root is the identity used every day, its password
and second factor sit in the same places, and the same leak loses the account and the way to
recover it.

## What to do with it instead

Put it in a drawer, and make the drawer good:

- a long random password kept in a password manager, never typed from memory;
- a second factor on it — a hardware security key if you have one, an authenticator app if not;
- no access keys for root, ever; if the account has any, delete them. A key for root is a
  password with no second factor, usable from anywhere, for everything;
- the account's e-mail address pointing at a mailbox the organisation owns, such as a shared
  `cloud-owner@` address, rather than one person's inbox, so it survives that person leaving.

Then create the identity you actually work with, which is the subject of the next two sections. If
the work needs full rights, give that identity full rights; it is still better than root, because
it can be limited later, it appears in the log under its own name, and removing it does not remove
the account.

The same shape exists at every provider under another name, though none of them is quite the same
object as root. At Google Cloud it is the super administrator of the organisation's Google Workspace or Cloud
Identity; at Azure, the Global Administrator role in Microsoft Entra ID. In an organisation of many
AWS accounts there is also a way to put limits above the root user of each member account, from the
organisation that owns it. That is `aws-foundations`' subject, and it does not change the advice:
the root user is for the few things only it can do.
