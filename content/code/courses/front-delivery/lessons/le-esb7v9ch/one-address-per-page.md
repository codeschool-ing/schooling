---
title: One address per page
version: 1
---

**Every page should have exactly one address, and every other spelling of it should redirect there.** A
site reachable as `example.com` and `www.example.com`, over `http` and `https`, with and without a
trailing slash, has eight addresses for its home page. People share whichever they landed on, search
engines count each as a separate page, and analytics splits the visits between them.

The common belief is that this is a search-engine concern. It is also a correctness one: cookies are set
per host, so a person signed in on `www.example.com` is signed out on `example.com`, and a service
worker, front-performance lesson 10, registers per origin.

## Pick one of each

| choice | the usual answer | how the others arrive |
|---|---|---|
| `https` or `http` | `https` | the host redirects port 80, as `host.mjs` did with its 308 |
| apex or `www` | either, said once | the host's domain settings redirect the other with a 301 |
| `/course/git` or `/course/git/` | whichever the app's links use | a rule, or the host's own normalisation |

All four hosts let you mark one domain as primary and redirect the others to it. Do it on the day the
domain is added, because the redirect is permanent and browsers remember it.

## Trailing slashes

Hosts normalise paths in their own ways, and it is worth knowing your host's before writing links.
Cloudflare Pages, for instance, documents that it redirects `/contact.html` to `/contact` and
`/about/index.html` to `/about/`. A host that serves a folder's `index.html` at both `/about` and
`/about/` without redirecting has created two addresses for one page.

The planner's links never end in a slash, so its own screen for `/course/git/` is *Not found*: the app
compares the path exactly. Either the app accepts both spellings, or the host redirects one to the other;
what matters is that the choice is made once, written down, and applied everywhere.

## Saying which one is right

Inside the page, `<link rel="canonical" href="https://example.com/course/git">` tells search engines
which address is the real one when a page is reachable at several. It is a statement, not a redirect: it
does nothing for the person in the browser, and a redirect is still the fix. Use both where the duplicates
cannot be removed, such as addresses with tracking parameters on them.
