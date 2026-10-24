---
title: What must not be kept
version: 1
---

**A cache that keeps the wrong thing is worse than no cache**: it is fast and wrong, and the person
looking at it cannot tell. Three cases decide most of it.

## Pages with someone's data in them

**A page that shows one person's data must never reach a shared cache.** If a CDN kept the page of a
signed-in student, the next person to ask for that address would be shown it, which is a leak, not a
performance problem. Such a page is sent `private`, so only that person's browser may keep it, or
`no-store` when even their own browser should not, as for a page with payment details. The safe default
for anything that depends on a cookie is `private, no-cache`.

The planner's pages are the same for everybody, so `no-cache` without `private` is right for it, and the
next section lets a shared cache keep them for a few seconds.

## Things that change at the same address

**A long lifetime on a file that can change is a promise the next deploy breaks.** The classic case is a
script called `app.js`, sent with `max-age=31536000`: the next build writes a new `app.js`, and every
returning visitor keeps running the old one for up to a year, against an API that has moved on. The fix is
not a shorter lifetime but a hashed name, so the new version is a new address. A lifetime is safe exactly
when the name changes with the content.

## Answers that are not reads

**Only `GET` and `HEAD` are cached in practice.** The planner's `POST /vitals` is never kept by anybody. A
`GET` that changes something, such as a link that deletes, is a bug for many reasons, one of them that a cache
may answer it without the server ever hearing of it.

## And one header in front of all of it

`Vary` again: an answer that depends on a request header and does not say so will be handed to somebody
whose request differed. Compression is the common one and the planner names it; a page that differs by
language, chosen from `Accept-Language`, must name that too, or one language is served to everybody.
