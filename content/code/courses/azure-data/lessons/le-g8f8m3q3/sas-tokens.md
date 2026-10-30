---
title: Shared access signatures, a permission you can hand over
version: 1
---

**A shared access signature, a SAS, is a set of query parameters that carries a permission and a
signature over it.** Whoever has the URL with the SAS on it can do exactly what the parameters say,
on exactly what they name, until the time they give, and nothing else. No account, no login, no key.
It is how Quitanda gives the finance team's spreadsheet one export for half an hour without giving
anybody the account key. People expect a token the service looks up and can revoke. A SAS signed
with the account key is not stored anywhere: the service checks the signature against the key on
each request, which is what makes it cheap, and what makes it hard to take back.

## Without one, and with one

A request with no signature at all, as anybody on the internet could send it:

@@CAP anonymous@@

**403, `AuthorizationFailure`.** The container is private, so a request signed by nobody is refused.
Now a SAS for reading that one blob, valid for thirty minutes from now:

@@CAP sas@@

The parameters are the whole permission, and they are readable by anybody holding the URL:

| parameter | means | here |
|---|---|---|
| `se` | signed expiry, in UTC | thirty minutes from the command |
| `sp` | signed permissions | `r`, read |
| `sv` | the storage service version that signed it | as printed |
| `sr` | the signed resource | `b`, one blob |
| `sig` | the HMAC over all of the above, with the account key | as printed |

**The read worked with no key at all**, and the write with the same SAS was refused with
`AuthorizationPermissionMismatch`: the signature is valid, and it does not grant `w`.

## What the signature binds

@@CAP sas-bound@@

Three refusals. **The SAS is bound to the name**: the same token on the 28 October export is refused,
because the signature was computed over the path of the 29th. **It is bound to its own parameters**:
changing `sp=r` to `sp=rw` in the URL does not grant a write, it breaks the signature, and the service
refuses the request outright. And **it is bound to its time**: a SAS whose expiry was 29 October at
noon, a day before this capture, is refused with 403. Azurite refuses all three, as Azure does.

That last point is the useful half of a SAS and its weakness together. The expiry is the only end a
key-signed SAS has. Until then, a URL pasted into a chat channel, a support ticket or a log file is a
working credential for whatever it names, and nothing on the account shows that it exists. **Keep the
expiry short, give the smallest permission and name the smallest resource**: one blob for thirty
minutes, rather than a whole account for a year. The next section shows the one way to revoke a SAS
before its time without rotating the key.

## The three kinds

| kind | signed with | names |
|---|---|---|
| service SAS | the account key | one container, blob, queue or table |
| account SAS | the account key | services and operations across the account |
| user delegation SAS | a key Microsoft Entra ID issues to a signed-in identity | blobs and containers |

The two above are service SAS. **The user delegation SAS is the one Microsoft recommends for blobs**,
according to its documentation, because nothing in it comes from the account key: the person or the
program signing it has signed in with Microsoft Entra ID, asked the service for a user delegation key
valid for at most seven days, and signed the SAS with that. Its permissions can be no more than the
signer's own, and revoking the delegation keys revokes every SAS made from them. The command line
makes one with `--as-user --auth-mode login`, which needs a real sign-in and was not run here.
