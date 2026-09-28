---
title: People sign in once, with a second factor
version: 1
---

The arrangement most small teams start with is a user per person in every cloud account, each with
a password and often an access key. It works, and it multiplies: three accounts and six people is
eighteen users, eighteen passwords and however many keys, each one a thing that has to be created on
the first day and remembered on the last. The person who leaves keeps a working key in the account
nobody thought of.

## The identity lives in one place

Most organisations already have one place where every person has an account: the **identity
provider**, or IdP, that runs their e-mail and their sign-in to everything else — Microsoft Entra ID,
Google Workspace and Okta are common ones. Federation means the cloud account trusts that provider
to say who somebody is, instead of keeping its own list of passwords.

A sign-in then goes like this:

1. The person opens the organisation's sign-in page and signs in there, with a password and a
   second factor.
2. The identity provider sends the cloud provider a signed statement: this is Ana, she belongs to
   these groups. The statement is written in one of two standard formats, SAML 2.0 or OpenID
   Connect.
3. The cloud provider checks the signature against the identity provider it was told to trust, and
   maps Ana's groups to roles she may assume.
4. Ana gets temporary credentials for one of those roles — in the console, or on the command line —
   and they expire like any role's.

At AWS the service that does this for people is IAM Identity Center, and the capture in the previous
section showed its trace: `sso` in the credential chain is the CLI looking for a session left by a
sign-in of this kind. Nothing of it was run here; there is no identity provider in this
course either.

**Leaving becomes one change.** Disable Ana at the identity provider and she cannot sign in to any
account that trusts it. There is one honest gap: credentials already handed out keep working until
they expire. That is the argument for short sessions — an hour lost to a leaver is a very different
risk from a key that works for a year.

## The second factor, and which one

A second factor means that a stolen password is not enough. They are not all equal:

- a hardware security key, using FIDO2 or WebAuthn, answers only to the real site it was
  registered with, so a convincing fake sign-in page gets nothing from it;
- an authenticator app produces a six-digit code that changes every thirty seconds; it stops a
  password stolen yesterday, but a person on a fake page can be persuaded to type today's code into
  it;
- a code sent by text message is the weakest of the three, because the phone number itself can be
  moved to another SIM by somebody who talks the phone company into it.

Put the factor at the identity provider, where every sign-in passes, and at the root user of every
account, which does not sign in through it.

## Programs outside the cloud, too

The same trust works for machines that are not in the cloud. A build pipeline that deploys to an
account used to need a stored access key. Now the pipeline's own platform issues it a signed token
for each run, the account trusts that platform in a role's trust policy, and the pipeline assumes
the role with the token — `assume-role-with-web-identity`, the third line of the credential chain.
GitHub Actions and GitLab CI both offer it. There is no key to store, and so none to leak.

## Long-lived keys for people are the last resort

Some tool will not do any of this. Then the key is the exception, with the smallest policy that tool
needs, rotated on a schedule, and written down somewhere a reviewer will see it. **A key for a person
is the thing federation exists to remove**, and every one that remains should have a reason
somebody can name.
