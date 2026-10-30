---
title: Three ways to prove it is the program
version: 1
---

**A service principal signs in with a credential, and Entra ID accepts three kinds.** They are not
three equal options. They are a ladder, and the course climbs it to the top:

| credential | what the program holds | what leaks if it leaks |
|---|---|---|
| **client secret** | a password Entra ID generated, valid until a date | the secret itself: whoever has it is the program until it expires |
| **certificate** | a private key whose public half is on the registration | the private key, which is harder to copy by accident than a string |
| **federated credential** | nothing: it trusts a token another identity provider issued | nothing stored, because nothing was stored |

## A secret, and the request it makes

The **client credentials flow** is how a program with no person behind it signs in: it sends its
client id and its proof to the tenant's `token_endpoint`, the one lesson 6 read out of the discovery
document, and receives an **access token** for the API it named. Here is that request with the
shop's made-up client id and a secret that is plainly not one, sent to `organizations`:

```
ana@laptop:~/azure/deploy$ curl -sS -X POST https://login.microsoftonline.com/organizations/oauth2/v2.0/token -d client_id=00001111-aaaa-2222-bbbb-3333cccc4444 -d client_secret=not-a-secret -d grant_type=client_credentials -d scope=https://management.azure.com/.default | jq '{error, error_codes, error_description: (.error_description | split(" Trace ID")[0])}'
{
  "error": "unauthorized_client",
  "error_codes": [
    700016
  ],
  "error_description": "AADSTS700016: Application with identifier '00001111-aaaa-2222-bbbb-3333cccc4444' was not found in the directory 'f8cdef31-a31e-4b4a-93e4-5f571e91255a'. This can happen if the application has not been installed by the administrator of the tenant or consented to by any user in the tenant. You may have sent your authentication request to the wrong tenant."
}
```

**`AADSTS700016` is Entra ID refusing a client id it cannot find in the directory it looked in.** The
secret was never checked, because there was no application to check it against. The directory named
in the message is the one Entra ID consulted for a request sent to `organizations` with no tenant of
its own; a real program sends the request to its own tenant's id instead, and the error then names
that tenant. The `scope` asked for a token for Resource Manager, written as its address followed by
`/.default`, which means "whatever roles this principal already has there".

A secret is the bottom of the ladder because **it is a string, and strings travel**. It gets pasted
into a configuration file, a chat message, a CI variable, a screenshot. Entra ID gives every secret an
expiry date, and Microsoft's own recommendation is under twelve months; the portal does not offer one
longer than two years. That limits how long a leaked secret works and adds a second problem: every
secret expires one day, often on a Friday, in the middle of something. **Each secret has an owner and
a calendar entry for its renewal**, or it should not exist.

A certificate is better because the private key never has to leave the machine that made it: the
registration holds only the public half. It still expires, and still has to be renewed and stored.

## And nothing at all

The top of the ladder holds no credential. **A federated credential is a rule on the registration
that says: trust a token issued by this other identity provider, for this subject.** The next section
uses it for the shop's pipeline, and lesson 8 shows the case where Azure itself is the other side and
the program does not even see the rule.
