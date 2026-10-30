---
title: The tenant is a directory, and anybody can ask where it is
version: 1
---

**Microsoft Entra ID is not a part of Azure that you switch on. It is the directory every Azure
tenant already is**, and it existed before any subscription did: the same directory holds the
identities for Microsoft 365, Teams and every application a company signs in to with its work
accounts. Until 2023 it was called Azure Active Directory, and half of what you will read online
still says so. The name changed; the product, its endpoints and its error codes did not.

A tenant holds four kinds of object, and this lesson and the next two take them in order:

| object | what it is | lesson |
|---|---|---|
| user | a person, or an account a person signs in with | 6 |
| group | a set of users, devices or other principals, given access once for all of them | 6 |
| application and service principal | a program's registration, and its identity inside one tenant | 7 |
| managed identity | an identity Azure creates and looks after for a resource | 8 |

Users, groups, service principals and managed identities are all **principals**: something that can
sign in, or be given a role. Lesson 9 gives them roles.

## Asking Entra ID where a tenant is

Entra ID answers on `login.microsoftonline.com`, the address lesson 1 read out of `az cloud show`.
Part of what it answers is public on purpose: before a program can ask anybody to sign in, it has to
know where to send them, and the answer is a **discovery document** that anybody may fetch. This one
is for `organizations`, the name that stands for "any work or school tenant":

```sh
mkdir -p ~/azure/entra && cd ~/azure/entra
```

```
ana@laptop:~/azure/entra$ curl -sS https://login.microsoftonline.com/organizations/v2.0/.well-known/openid-configuration | jq '{issuer, authorization_endpoint, token_endpoint, jwks_uri}'
{
  "issuer": "https://login.microsoftonline.com/{tenantid}/v2.0",
  "authorization_endpoint": "https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize",
  "token_endpoint": "https://login.microsoftonline.com/organizations/oauth2/v2.0/token",
  "jwks_uri": "https://login.microsoftonline.com/organizations/discovery/v2.0/keys"
}
```

**This is a real answer from Microsoft Entra ID**, the first one in the course. It is the OpenID
Connect standard's discovery document, and every identity provider that speaks the standard
publishes one at the same path. Four addresses in it matter:

- `authorization_endpoint` is where a **person** is sent to sign in, in a browser;
- `token_endpoint` is where a **program** asks for a token, which is lesson 7;
- `jwks_uri` holds the public keys that sign every token, so that anybody receiving one can check it
  came from Entra ID;
- `issuer` is what a token will say about who issued it, with `{tenantid}` filled in by the tenant
  that did.

Ask for a tenant that does not exist and Entra ID says so, in its own words:

```
ana@laptop:~/azure/entra$ curl -sS https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/v2.0/.well-known/openid-configuration | jq '{error, error_codes, error_description: (.error_description | split(" Trace ID")[0])}'
{
  "error": "invalid_tenant",
  "error_codes": [
    90002
  ],
  "error_description": "AADSTS90002: Tenant 'aaaabbbb-0000-cccc-1111-dddd2222eeee' not found. Check to make sure you have the correct tenant ID and are signing into the correct cloud. Check with your subscription administrator, this may happen if there are no active subscriptions for the tenant."
}
```

**`AADSTS90002` is the code for a tenant Entra ID has never heard of**, and `AADSTS` starts every
Entra ID error, a prefix left over from the old name. The id is the made-up tenant this course uses
for the shop, in the pattern Microsoft's own documentation uses, and the answer proves it is free.
The `jq` filter cut the description at its *Trace ID*, a value Entra ID makes up for every request
so that its support can find it, which a transcript cannot repeat.

**`.onmicrosoft.com` names are first come, first served.** Every tenant gets one at creation, and
the shop's tenant in this course is written `shop.onmicrosoft.com` because the shape is right. That
exact name is taken by somebody else: Entra ID answers for it. So this course gives the shop **a
domain of its own, `shop.example`**, which a real company would verify in its tenant by adding a
DNS record, and its people sign in as `bia@shop.example`. `.example` is reserved for documentation
and can never belong to anybody.

## A user is an object, and its name is not its id

```
ana@laptop:~/azure/entra$ az ad user list --display-name Bia
ERROR: Please run 'az login' to setup account.
```

Listing users is a question for **Microsoft Graph**, the API at `graph.microsoft.com` through which
everything in the directory is read and written, and it needs a sign-in like everything else. **Not
run.** With one, each user comes back with two names that people confuse:

- the **user principal name**, `bia@shop.example`, which she types to sign in. It looks like an
  e-mail address and need not be one; it can be changed, and it is, when somebody marries or a
  company renames its domain;
- the **object id**, a GUID Entra ID gave her when she was created, which never changes.

**Every permission, every log line and every group membership points at the object id.** A script
that stores who did what by user principal name loses the history the day the name changes, which
is exactly the failure that joining by a stable id prevents. Read the object id out of anything you
keep.

Users come in two types. A **member** belongs to the tenant: the shop's own staff. A **guest** is a
person from another organisation invited in, who signs in with their own organisation's account or
a personal one and appears in the shop's directory with `#EXT#` in their user principal name. The
shop's accountant, from an outside firm, is a guest: she gets access to the billing reports and the
shop never holds her password.
