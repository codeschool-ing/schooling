---
title: The other arrangement, and what it costs
version: 1
---

The lookup at the end of the previous reading is a real cost: every request, on every service, asks
a shared store who this is. So there is a second arrangement in wide use, and it removes the
lookup by moving the information into the credential itself.

## A statement that carries its own proof

Instead of an opaque identifier, the browser holds a **token** containing the facts — who this is,
what they are allowed to do, when it stops being valid — followed by a signature made with a key
only the server has.

The server verifies the signature and believes the contents. No table, no lookup, nothing shared.
Any service holding the key can check it, which is why this arrangement spread with systems built
out of many small services.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A session identifier is checked against a table, so deleting the row revokes it at once. A token is checked against a signature, so there is nothing to delete and it stays valid until it expires.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">a session identifier</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">checked against a table</text> <rect x=\"20\" y=\"88\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">costs a lookup on every request</text> <rect x=\"20\" y=\"140\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">delete the row and it ends at once</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">a signed token</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">checked against a signature</text> <rect x=\"380\" y=\"88\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">costs no lookup, and no shared store</text> <rect x=\"380\" y=\"140\" width=\"320\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nothing to delete: valid until it expires</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the same property is the advantage and the problem</text> <text x=\"360\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is why short lifetimes exist, and why the refresh brings the table back</text> </svg>", "caption": "Not old and new. One of them can be taken back and the other one cannot, and everything else follows."}
```

Two things about that are commonly misunderstood, and both matter.

**Signed is not encrypted.** The contents are readable by anybody holding the token, usually after
one decoding step that needs no key at all. The signature stops it being *changed*, not read. So
nothing goes in a token that you would not write on a postcard.

**Nothing checks it against reality.** The server believes the token because the signature is
valid, and the signature was valid the moment it was made. Which leads directly to the problem.

## You cannot take it back

A session identifier is checked against a table, so deleting the row ends it everywhere, within a
second.

A token is checked against a signature, so there is nothing to delete. If somebody's access is
withdrawn — they left the company, the account was compromised, the subscription ended — their
token keeps working until it expires, because every server that sees it reaches the same conclusion
it reached yesterday.

The usual answer is short lifetimes: a token good for fifteen minutes, plus a longer-lived
**refresh token** used to obtain a new one. Revocation then means refusing the refresh, and the
worst case is fifteen minutes of access you wanted to stop.

Notice what that costs. The refresh token has to be checked against something that can be
revoked — which is a table, in a shared store, consulted on every refresh. The lookup came back.
It is simply consulted less often, which is a real improvement and not the thing it was sold as.

## Where to keep it

This is the decision that actually reaches the code, and it is usually made by copying a tutorial.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A credential kept in a cookie with HttpOnly is unreadable to scripts and needs SameSite against forgery. A credential kept in local storage is readable by every script on the page and has no equivalent of HttpOnly.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">in a cookie</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">HttpOnly: no script reads it</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">SameSite: no forged request carries it</text> <rect x=\"20\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the browser attaches it for you</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">in local storage</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".28\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no HttpOnly exists for it</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".28\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">every script on the page reads it</text> <rect x=\"380\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your code attaches it by hand</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the old argument for the right-hand side was request forgery</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">SameSite answered that, and nothing answers the row above it</text> </svg>", "caption": "The choice is not where it is tidier to keep. It is which attack you are choosing to be exposed to."}
```

**In a cookie**, with `HttpOnly`, `Secure` and `SameSite`. The browser attaches it, no script can
read it, and the attributes from two readings ago apply exactly as before.

**In local storage**, read by the page's own code and attached by hand to each request. This is the
arrangement most tutorials show, and it has one property worth stating plainly: **there is no
`HttpOnly` for local storage.** Any script running on the page can read everything in it. The
cross-site scripting attack from the attributes reading — the one `HttpOnly` was invented to
answer — works again, in full.

The trade people describe is *cookies are vulnerable to request forgery, local storage is not*, and
it was true before `SameSite` existed. Today the honest summary is narrower: a cookie with the
three attributes set is the safer default, and local storage is a choice you make when something
about your architecture requires it, knowing what it gives up.

## What one actually looks like

Worth seeing once, because it demystifies the thing and makes the warning above concrete.

The common format is three pieces separated by full stops: a small description of how it was
signed, the claims themselves, and the signature. The first two are ordinary text, encoded in a way
that survives being put in a header — an encoding, not a cipher. Paste one into any of the sites
that decode them and you will read somebody's user id, their role and an expiry time, with no key
and no permission.

That is the postcard, seen. It is also why *the token is encrypted* is one of the more dangerous
things a team can believe about its own system.

## The mistake that the format made possible

One more thing, because it is the best illustration of why a server must never take instructions
from the credential it is checking.

That first piece — the description of how it was signed — is part of the token, and therefore part
of what the sender controls. Early libraries read it and used whatever it named. Somebody noticed
that one of the permitted values meant *not signed at all*, wrote a token claiming to be an
administrator, said it was unsigned, and was believed.

The fix is stated as a rule worth carrying beyond tokens: **the verifier decides the algorithm.**
What arrives may be checked against what was expected; it may never be allowed to choose.

## Choosing between the two arrangements

Neither is the modern one and neither is the old one; they answer different questions.

Sessions when you need to be able to end access immediately, when everything is one application,
and when a lookup per request is affordable — which, for most sites, it is.

Tokens when many services need to check the same credential without sharing a store, when the cost
of that store is real, and when you can live with revocation being delayed by a known amount.

And the honest note to end on: a great many systems use tokens because tokens are what the tutorial
used, discover later that they cannot sign anybody out, and add a table to fix it. Choosing on
purpose is most of the value of knowing both.
