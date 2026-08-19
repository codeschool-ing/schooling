---
title: Session: the cookie that does not carry the secret
---

Keeping real data in the cookie is a bad idea — the user edits whatever they like. The standard is for the cookie to carry only a random **session identifier**, with the server holding the data associated with it.

Hence the consequence that shows up at the first serious deploy: if the application runs on two servers and the session lives in the memory of one of them, half the requests cannot find the session and the user gets "logged out" at random. That is why a session in production lives somewhere shared — Redis, a database — or does not exist at all, and the state travels in a signed token.

Logging out for real means invalidating the session **on the server**. Deleting the cookie only removes the key; if somebody copied the identifier beforehand, it still works.
