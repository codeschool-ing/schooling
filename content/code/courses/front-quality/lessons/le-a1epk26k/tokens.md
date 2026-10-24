---
title: A token that carries its own meaning
version: 1
---

**A JSON Web Token is three pieces of text joined by dots: a header, a body of claims, and a
signature over the first two.** The server that signs it can later check, with no memory at all, that
the claims are the ones it wrote. Nothing else about a JWT is secret, and the most common mistake with
one is to think otherwise.

To see every part of it, here is one written by hand with Node's `crypto`, signed with HMAC-SHA-256,
the algorithm a JWT calls `HS256`. Save it as `server/jwt.mjs`:

```javascript
// server/jwt.mjs
import { createHmac, timingSafeEqual } from "node:crypto";

const encode = (value) => Buffer.from(JSON.stringify(value)).toString("base64url");
const decode = (part) => JSON.parse(Buffer.from(part, "base64url").toString());
const mac = (text, secret) => createHmac("sha256", secret).update(text).digest();

export function sign(claims, secret) {
  const head = encode({ alg: "HS256", typ: "JWT" });
  const body = encode(claims);
  return `${head}.${body}.${mac(`${head}.${body}`, secret).toString("base64url")}`;
}

export function verify(token, secret, now = Math.floor(Date.now() / 1000)) {
  const [head, body, signature = ""] = token.split(".");
  if (decode(head).alg !== "HS256") throw new Error("unexpected algorithm");
  const given = Buffer.from(signature, "base64url");
  const expected = mac(`${head}.${body}`, secret);
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) throw new Error("bad signature");
  const claims = decode(body);
  if (now >= claims.exp) throw new Error("expired");
  return claims;
}
```

`verify` refuses three things, in order: a header naming any algorithm but the one it expects, a
signature that does not match, and a token past its `exp`. The first check is not decoration. A JWT
names its own algorithm, and a verifier that believed the token about how to check it could be told
`"alg": "none"`; the libraries that once did are why every guide now says to fix the algorithm on the
server.

And a short program that signs a token for ana, valid for eight hours on 20 October 2026, then tries
three ways of getting a different answer out of it. Save it as `server/try-jwt.mjs`:

```javascript
// server/try-jwt.mjs
import { sign, verify } from "./jwt.mjs";

const secret = "a secret only the server knows";
const token = sign({ sub: "ana", iat: 1792483200, exp: 1792512000 }, secret);
console.log("token:   ", token);

const [head, body, signature] = token.split(".");
console.log("payload: ", Buffer.from(body, "base64url").toString());
console.log("verified:", verify(token, secret, 1792490000));

const forged = Buffer.from(JSON.stringify({ sub: "bruno", iat: 1792483200, exp: 1792512000 })).toString("base64url");
for (const [what, attempt, now] of [
  ["another name", `${head}.${forged}.${signature}`, 1792490000],
  ["another secret", sign({ sub: "ana", iat: 1792483200, exp: 1792512000 }, "a guess"), 1792490000],
  ["after exp", token, 1792512000],
]) {
  try {
    verify(attempt, secret, now);
    console.log(`${what}: accepted`);
  } catch (error) {
    console.log(`${what}: refused, ${error.message}`);
  }
}
```

```
ana@dev:~/planner$ node server/try-jwt.mjs
token:    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmEiLCJpYXQiOjE3OTI0ODMyMDAsImV4cCI6MTc5MjUxMjAwMH0.nwOyKoscIUR4jcHTnfmb76Y3JUtCzYPI-JQYg_-Y3VY
payload:  {"sub":"ana","iat":1792483200,"exp":1792512000}
verified: { sub: 'ana', iat: 1792483200, exp: 1792512000 }
another name: refused, bad signature
another secret: refused, bad signature
after exp: refused, expired
```

**Read the second line before anything else: the payload is in plain sight.** Base64url is an
encoding, not encryption, and anybody holding the token reads `sub`, `iat` and `exp` exactly as the
server wrote them. A JWT may never carry anything its holder should not see. What the signature buys
is that nobody can **change** it: a body naming bruno under ana's signature is refused, a token signed
with a guessed secret is refused, and at 16:00 UTC, the `exp`, ana's own token is refused too.

## The price of carrying the meaning

The server checked all of that without looking anything up, which is the reason tokens are used:
any number of servers can check one, and none of them has to share a memory. **The price is that
nothing can take it back.** A session id is forgotten by deleting one entry; a signed token is valid
until its `exp`, whoever holds it, unless every server keeps a list of tokens it no longer accepts,
which is a session store again with extra steps. That is why access tokens are made to expire in
minutes rather than hours, and the next section weighs the two.

Commit the server and the two files of this section:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A server with one account, a session cookie, and a JWT by hand"
```
