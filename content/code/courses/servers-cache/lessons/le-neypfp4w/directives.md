---
title: The words in Cache-Control
version: 1
---

`Cache-Control` is a list of directives, separated by commas, and four pairs of them cover nearly
everything a response needs to say. The names were chosen badly enough that every pair contains a
trap.

| directive | what it says | the trap |
|---|---|---|
| `max-age=N` | fresh for N seconds | none; this is the one to start from |
| `s-maxage=N` | fresh for N seconds **in a shared cache**, overriding `max-age` there | the browser ignores it |
| `public` | a shared cache may store this, even where it would not by default | rarely needed with `max-age` present |
| `private` | only the person's own browser may store this | a shared cache that ignores it serves one person's page to everybody |
| `no-cache` | store it, but **check with the origin before every use** | it does not mean "do not cache" |
| `no-store` | do not store it anywhere, at all | the one that does mean "do not cache" |
| `must-revalidate` | once stale, never serve it without checking, even if the origin is down | turns an origin outage into errors instead of old pages |
| `immutable` | this exact URL will never change; do not even check | only true for a URL with the version in it (lesson 6) |

Three combinations cover most real responses:

- **a page that differs per person**, an account page, a basket: `private, no-cache`, or `no-store`
  where it holds anything sensitive, so it is never written to a shared cache and never served from
  anybody's disk without asking;
- **a public page that changes**, a catalogue listing: `public, max-age=60`, or `max-age=60,
  s-maxage=300` to let the server's own cache keep it longer than browsers do, since the server's
  cache can be purged and browsers cannot (lesson 6);
- **a file whose name carries its version**, `site.3f2a91c4.css`: `public, max-age=31536000,
  immutable`.

**`no-cache` is the most misread word in HTTP caching.** It allows storing and forbids serving without
asking, which makes it ideal for something that changes unpredictably but is expensive to send
again: the copy is kept, every use costs a quick check, and the check costs almost nothing when the
answer has not changed. That check is the next section.
