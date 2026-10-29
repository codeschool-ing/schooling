---
title: PKCE, worked through with the standard's own numbers
version: 1
---

**PKCE, Proof Key for Code Exchange, ties the code from step 3 to the app that asked for it, with a
secret made fresh for each sign-in.** It is RFC 7636, and it takes two values:

1. The **code verifier**, a random string of 43 to 128 characters, made by the app at the start and
   kept to itself.
2. The **code challenge**, the SHA-256 hash of the verifier, written in base64url, sent to the provider
   in step 1 with `code_challenge_method=S256`.

At step 4 the app sends the verifier itself, and the provider hashes it and compares it with the
challenge it kept. **Somebody who intercepted the code at step 3 has the code and not the verifier**,
which never left the app until that moment, and a hash cannot be run backwards to find it.

The RFC publishes a worked example, in its Appendix B, so any implementation can check itself against
it. The verifier there is `dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk`, and the challenge it gives is
`E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM`. Node's own `crypto` does the arithmetic in one line:

```
ana@dev:~/planner$ node -e 'const { createHash } = require("node:crypto"); console.log(createHash("sha256").update("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk").digest("base64url"))'
E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
```

**The same challenge, to the last character.** That is a test in the sense this course means: an
expected value worked out by somebody else, independently, and the code agreeing with it. A real
sign-in makes a new verifier every time from 32 random bytes, which in base64url is exactly the 43
characters the minimum asks for:

```
ana@dev:~/planner$ node -e 'console.log(require("node:crypto").randomBytes(32).toString("base64url").length)'
43
```

`S256` is the method to use; the RFC also allows `plain`, where the challenge is the verifier itself,
and that protects nothing a passive listener could not read.
