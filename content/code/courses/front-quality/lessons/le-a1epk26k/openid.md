---
title: OpenID Connect, and which token says who you are
version: 1
---

**OAuth answers *what may this app do*, and says nothing about *who is this person*.** OpenID Connect
is a layer on top of the same flow that answers the second question. Ask for the scope `openid` in
step 1, and step 5 brings back a second token beside the access token: the **ID token**, a JWT about
the person who signed in.

The two are easy to confuse and must not be:

| | ID token | access token |
|---|---|---|
| it is for | the app, to learn who signed in | the API, to decide what a request may do |
| the app should | check it once, then read it | send it, and never parse it |
| its audience, `aud` | the app's own client id | the API it was issued for |
| send it to your API | no | yes |

An ID token is a JWT like the one in the last section but one, signed by the provider with a key pair
rather than a shared secret, so anybody can check it with the provider's public key and only the
provider can make one. Its claims are standard: **`iss`**, who issued it, which must be the provider
you expect; **`aud`**, whom it is for, which must be your client id; **`exp`**, when it stops being
valid; **`sub`**, a stable identifier of the person at that provider; and **`nonce`**, a value your
app sent in step 1 and must find again here, which ties this token to that sign-in.

## Use the provider's library

Checking those five claims and a signature is a short list, and every item on it has been got wrong
in a library that was used in production. **Use a certified OpenID Connect client library** for the
browser, or the one your provider publishes, and keep your own code to what it is told: who signed
in. What `jwt.mjs` showed by hand is there to make the library's work legible, not to replace it.

And once the app knows who signed in, the question of lesson 5 is answered and the question of lesson 6
begins: the app now holds tokens worth stealing, in a page that runs code.
