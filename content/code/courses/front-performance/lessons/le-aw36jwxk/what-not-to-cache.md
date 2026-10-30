---
title: What a worker must not keep
version: 1
---

**Everything lesson 9 said a shared cache must not keep, a worker must not keep either**, and two things more,
because a worker's cache lasts until the worker decides otherwise.

- **Answers that are not `GET`.** The planner's worker returns early for anything else, so the `POST` to
  `/vitals` goes to the network as if the worker did not exist. Cache Storage refuses to store a `POST` anyway;
  the early return makes the intention plain.
- **Other people's servers.** The planner's worker only answers its own origin. A response from another
  server, fetched without CORS, is *opaque*: the worker can store it but cannot read its status, so a cached
  error looks like a cached success, and browsers count each opaque response as several megabytes of quota.
- **Errors.** `fetchAndKeep` keeps only an answer whose `ok` is true. A 500 page kept by network first would be
  what the visitor sees offline, forever, with no way to tell it from the real page.
- **A person's data.** A page with one signed-in person's data in it, kept by a worker, is still there after
  they sign out, on a shared computer, for the next person. Network only, or a cache cleared on sign-out.
- **Without limit.** Cache Storage counts against the site's share of the disk. A worker that keeps every page
  and every picture it is ever asked for grows with every visit; the planner's is small because the planner is,
  and a real catalogue would cap the number of pages it keeps, deleting the oldest.
