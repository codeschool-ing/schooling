---
title: CSRF in real projects
version: 1
---

This lesson wrote the token check by hand so every line could be read. In a real Flask project,
use the extension that does it: **Flask-WTF's `CSRFProtect`** adds a token to every session, checks
it on every unsafe request, and offers `csrf_token()` to templates, which is what this lesson's code
imitated. Django has CSRF protection switched on by default, and most other frameworks have an
equivalent. What follows is about the cases the defaults leave to you.

### Exemptions are the weak point

Every framework lets a route opt out, usually for a webhook a payment provider calls, which cannot
know the token. **An exempted route is a route with no CSRF protection**, so it has to protect itself
another way: the webhook proves who sent it by a signature the provider computes with a shared secret,
and it changes only what the provider is entitled to change. Review every exemption as you reviewed
every route in lesson 12.

### JSON APIs

An API that accepts only `application/json` and is called by the portal's own JavaScript is harder to
forge, because a plain HTML form cannot send that content type. Harder is not immune:

- An endpoint that **also** accepts a form body, which many frameworks do by default, is as exposed
  as any form.
- **CORS** decides which other origins may read responses and send non-simple requests. A
  configuration that reflects any `Origin` back with credentials allowed gives every site on the
  internet the same reach as the portal's own pages. Allow the origins you name, and no others.

The same three defences apply: a token in a header the portal's JavaScript sets, `SameSite`, and the
origin check.

### Less obvious targets

- **Sign-in.** A forged sign-in puts the patient into an account the other site controls, and
  whatever she then types, her health history included, goes into that account. The sign-in form
  needs a token too, from the anonymous session lesson 10 gave every visitor.
- **Sign-out.** Mostly a nuisance, and it is why sign-out is a `POST` with a token, never a link.
- **Anything with `GET`.** A route that changes data on `GET` is outside every defence in this lesson,
  because `SameSite=Lax` lets top-level `GET` navigations through and the token is only checked on
  unsafe methods. The rule from the first section is not style: **`GET` reads, the rest writes.**

### What is not a defence

- **A secret cookie.** The browser sends every cookie, the secret ones included.
- **Checking `Referer` alone.** It is often stripped by privacy settings and proxies, and a policy
  that allows a missing `Referer` allows the forged request too.
- **Multi-step forms.** A sequence of forged requests is still forged.
- **HTTPS.** It protects the request in transit and says nothing about which page sent it.
