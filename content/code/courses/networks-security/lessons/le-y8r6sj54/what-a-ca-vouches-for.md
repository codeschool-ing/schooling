---
title: What a certificate authority vouches for
version: 1
---

Lesson 11 ended on a gap: a signature proves who signed only if you already know whose public key you
hold. Two parties who have never met cannot exchange keys in person, and the internet has billions of
such pairs. **A public key infrastructure (PKI)** closes the gap with a third party both already trust.

A **certificate** is a statement, signed by a **certificate authority** (CA): *this public key belongs
to this name, for this period, for these purposes*. A client that trusts the CA's key can check the
signature and so trust the binding, without ever having met the server.

`networks` lesson 6 read certificates as a client does and broke them four ways. This lesson is on the
other side of the counter: **running** the authority, for the company's own names, and deciding what
it will and will not sign.

What a CA actually vouches for is narrower than people assume:

| a certificate says | it does **not** say |
|---|---|
| the holder of this key controlled this name when the certificate was issued | that the site is honest, safe or legitimate |
| the CA checked that control in the way its policy states | that the key is still in the right hands today |
| the binding holds between two dates | that nobody else has a certificate for the same name |

A phishing site can hold a perfectly valid certificate for the lookalike name it registered; the
padlock says the connection reaches that name and nothing about the name. The rest of the lesson is
about making the statement as reliable as it can be: whose name, which key, and how to take a
statement back.
