---
title: When the company already knows who you are
version: 1
---

Six roles with six passwords is manageable. Six hundred people across a data warehouse, a BI
tool, a notebook service and three databases is not: everybody ends up with a password per
system, nobody changes them, and on somebody's last day the person doing the offboarding has to
remember every system they had an account on.

**Single sign-on moves authentication out of each system and into one place**, the company's
**identity provider**. The person proves who they are there — with a password and, almost always,
a second factor — and every other system accepts the provider's word. Disabling one account in
the provider closes every door at once, which is what makes offboarding a single action instead
of a checklist.

How the word is passed depends on the system:

| method | how it works | where it appears |
|---|---|---|
| **LDAP** | the database asks a directory server to check the password | PostgreSQL's `ldap` method; Active Directory |
| **Kerberos / GSSAPI** | the person's machine holds a ticket the database can verify, with no password sent | PostgreSQL's `gss` method; Windows domains |
| **OIDC and SAML** | the browser is sent to the provider and comes back with a signed token | cloud warehouses, BI tools, notebook services |
| **client certificates** | the client proves it holds a private key the company's CA signed | PostgreSQL's `cert` method; lesson 3 uses it for `etl_loader` |

PostgreSQL 16 supports the first two and the last one in `pg_hba.conf`, beside `scram-sha-256`;
OIDC arrives in PostgreSQL 18, which this lab does not run. None of the three was configured in
the lab, because each needs a server the lab does not have — a directory, a Kerberos realm, an
identity provider. The table describes them; it is not a transcript.

## The second factor lives at the provider

A database protocol has no place to ask for a code from a phone. **Multi-factor authentication is
enforced where the person signs in**, which is the identity provider for a cloud warehouse and the
BI tool, and the VPN or the bastion host for a database reached on its own network. So a company
that "requires MFA for data access" usually means: requires it to reach the network or the tool
the database is behind. Asking where that is true and where it is not — a service account, an
old local password nobody removed — is how you find the door without one.

## What stays local

Even with single sign-on, two kinds of login stay in the database:

- **the superuser**, reachable only through the operating system (`peer`), so that the identity
  provider being down never locks the people who fix things out of the thing they fix;
- **service accounts**, which have no person to sign in and are authenticated by a secret or a
  certificate, and governed by the rules of the last section.

Both are what an access review looks at first, because the provider's offboarding does not reach
them.
