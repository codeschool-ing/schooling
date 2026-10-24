---
title: The normalised cache
version: 1
---

**Apollo's cache does not store answers; it stores objects, one entry each, keyed by type and id.** Step
1 asked for three courses with their sessions, and the cache came out as nine entries and a root:

```
1. keys: ["Session:1","Session:5","Course:html-css","Session:2","Session:4","Session:6","Course:javascript","Session:3","Course:git","ROOT_QUERY"]
   Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":false}
```

Taking a nested answer apart into flat entries like this is **normalisation**, and it is what makes the
cache more than a list of past answers.

- **The key is `__typename` and `id`.** Apollo adds `__typename` to every object in every query it
  sends, so each object comes back saying what type it is. `Session:6` is session 6 whichever query it
  arrived in.
- **Objects point at each other.** A course's entry holds its sessions as references, `{"__ref":
  "Session:3"}`, not as copies. There is one session 6, and every query that includes it reads that one.
- **`ROOT_QUERY`** records what each field of `Query` answered: that `courses` is these three references.
  A later query for `courses` with the same fields can be answered from it.

## Why one entry matters

Two places on a page showing session 6, the course page and a weekly summary say, are two queries that
both reach `Session:6`. Change that entry and both see the change, with no code saying that they are
related. That is step 3, two sections on, and it is the single most useful thing a GraphQL
client does.

## When there is no `id`

Normalisation needs something to key on. An object whose type has no `id` field, or a query that did not
ask for it, is stored inside its parent instead, and updates to it no longer reach other queries. **Ask
for `id` on every object you want the cache to keep track of**, which is why the planner's fragment from
lesson 9 has `id` on both the session and its course. A type whose identity is another field is told so
in the cache's options, with `typePolicies: { Course: { keyFields: ["slug"] } }`.
