---
title: Cookies: the memory HTTP does not have
---

HTTP remembers nothing: every request arrives as if it were the first. The **cookie** is the workaround that became foundation — the server sends a `Set-Cookie` and the browser hands that value back on every following request to that domain.

The attributes are what separates a safe cookie from a security problem. `HttpOnly` stops the page's JavaScript from reading the value, which limits the damage of an XSS. `Secure` stops it being sent outside HTTPS. `SameSite` controls whether the cookie travels on requests originating from another site, which is the defence against CSRF.
