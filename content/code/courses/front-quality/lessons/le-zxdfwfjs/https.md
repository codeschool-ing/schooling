---
title: What HTTPS gives, and what it does not
version: 1
---

**HTTPS is HTTP inside a TLS connection, and TLS gives three things: nobody on the way can read the
traffic, nobody on the way can change it, and the browser knows it is talking to the server the
address names.** The third is the one people forget. A certificate signed by an authority the browser
trusts is proof that `planner.example` is `planner.example`, and without it a café's Wi-Fi could
answer in its place.

What HTTPS does **not** give is any statement about the site itself. A page full of injected scripts
is served over HTTPS as happily as a clean one; a padlock says the connection is private, not that
what came down it is safe. The rest of this lesson is about the second half: headers that tell the
browser what the page is allowed to do.

## Three rules that follow from it

- **Every resource over HTTPS, with no exceptions.** A page loaded over HTTPS that pulls one script
  over plain HTTP has handed that script to anybody on the network; browsers block such **mixed
  content** for scripts and styles, and warn about the rest.
- **Cookies that matter are `Secure`**, as lesson 6 made the planner's, so they never travel without
  TLS.
- **The first visit is the weak one.** Somebody who types `planner.example` reaches `http://` first, and
  a redirect to HTTPS can be intercepted before it happens. The server closes that gap with one header,
  `Strict-Transport-Security`, which tells the browser to use HTTPS for this site and never ask again.

Here is that header on a real site, nodejs.org, which you downloaded Node from:

```
ana@dev:~/planner$ curl -s -o /dev/null -D - https://nodejs.org/ | grep -i strict-transport-security
strict-transport-security: max-age=31536000; includeSubDomains; preload
```

`max-age=31536000` is a year, in seconds; `includeSubDomains` covers every name under it; `preload`
asks to be built into browsers themselves, so that not even the very first visit goes over HTTP.

## The planner, here and when published

`http://localhost` is the one address browsers treat as secure without TLS: `Secure` cookies work there,
which is why lesson 6 could use them. HSTS over plain HTTP is ignored, so the planner's development
servers do not send it. **HTTPS, certificates and HSTS are set where the site is published**, by the host
or the server in front of the files, and lesson 4 of `front-delivery` covers that. What this lesson adds
is the part that travels with the site whoever hosts it: its Content Security Policy and the headers
around it.
