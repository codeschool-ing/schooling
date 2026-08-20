---
title: Subdomains: when to separate
---

A subdomain is free and unlimited, so the question is never "can I?", it is "should I?". `app.example.com` and `example.com/app` solve the same need in different ways.

A subdomain really does separate: each can point at a different server, have a certificate of its own and, for many security purposes, is treated as another site — one's cookie is not sent to the other by default. That is what you want for the admin panel, for the API and for the test environment.

A path on the same origin shares everything — session, cookie, certificate — and avoids the extra configuration. That is what you want when the parts are the same product and talk to each other constantly.
