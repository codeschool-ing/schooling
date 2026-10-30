---
title: Security defaults, and the second factor Azure now demands
version: 1
---

**Lessons 9 and 10 decided what an identity may do once Azure knows who it is. This lesson is about
the moment before: how sure Azure is that the person typing is the person named.** A password alone
is a weak answer. It is guessed, reused from a site that leaked, typed into a convincing copy of the
sign-in page, and none of that leaves a trace the owner of the password would notice. A second factor,
something the person has as well as something they know, is the cheapest large improvement there is.

Everything in this lesson happens inside a real tenant at the moment of signing in, so **none of it
was run**, with two exceptions: the lab shows which application the Azure CLI signs in as, and the
next section checks a conditional access policy against its schema.

## Security defaults

Microsoft's documentation describes **security defaults** as a fixed set of protections, switched on
at no extra cost, for tenants without the premium licences that conditional access needs. A tenant
created since October 2019 may well have them on already. They do four things:

- **every user registers for multifactor authentication**, and is asked for it when Entra ID judges
  the sign-in risky;
- **administrators are asked for it every time** they sign in;
- **anybody reaching Azure management**, the portal, the CLI, PowerShell, is asked for it;
- **legacy authentication is blocked**: old protocols that send a password and cannot carry a second
  factor, which are where Microsoft says most compromising sign-in attempts come from.

**They are all or nothing.** Security defaults cannot be tuned: no exceptions, no conditions, no
report on what they would do. That is their virtue for a small tenant and their limit for a larger
one, and switching them off without putting conditional access in their place leaves a tenant with
less protection than it had. The next section is what replaces them.

## Mandatory MFA for Azure

Since 2024, **Microsoft has enforced a second factor for every user who signs in to manage Azure**,
whatever the tenant's own settings. Its documentation describes
two phases:

| phase | from | applications | operations |
|---|---|---|---|
| 1 | October 2024, rolled out gradually | the Azure portal, the Microsoft Entra admin center, the Intune admin center | any create, read, update or delete |
| 2 | 1 October 2025, rolled out gradually | the Azure CLI, Azure PowerShell, the Azure mobile app, infrastructure-as-code tools, the REST API | create, update and delete; reads are not affected |

**Workload identities are not affected by either phase**: service principals and managed identities,
lessons 7 and 8, sign in with a certificate, a federated token or the platform's own credentials, not
with a password and a phone. Microsoft's documentation draws the consequence plainly: a *user*
account used as a service account for automation now needs a second factor at each sign-in, so
automation running as a person should move to a workload identity.

## Which application the CLI signs in as

Each client in Microsoft's table has an application id, because each one is an application
registered in Entra ID, signing people in on its own behalf. The Azure CLI is one of them, and the
copy in your lab carries its id in its source:

```
ana@laptop:~/azure$ python3 -c 'from azure.cli.core.auth.constants import AZURE_CLI_CLIENT_ID; print(AZURE_CLI_CLIENT_ID)'
04b07795-8ddb-461a-bbee-02f9e1bf7b46
```

`04b07795-8ddb-461a-bbee-02f9e1bf7b46` is the same id Microsoft's table lists for the Azure CLI in
phase 2. **It is a public client**: an application with no secret, which signs in a *person* and
then acts on their behalf, with their roles. That is why mandatory MFA reaches it, and why a token
the CLI holds is worth exactly as much as the person who signed in. Lesson 7 draws the line between
an application like this one, acting for a person, and a service principal acting for itself.
