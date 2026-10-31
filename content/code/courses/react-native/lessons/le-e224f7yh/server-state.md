---
title: Server state is not like the rest
version: 1
---

**State that lives on a server is a copy you are borrowing.** The plan in lesson 9's provider belonged to
the app: it changed only when the app changed it. A plan fetched from a server can change on the server
at any time, from another phone, from a browser, from somebody's script. So the app's copy has
questions the provider's never had:

- **Is it here yet?** Fetching takes time, and the screen has to show something while it waits.
- **Did it arrive?** The server can be down, the network gone, the answer an error.
- **Is it still true?** A copy fetched ten minutes ago may not be.
- **Did my change reach it?** A press that marks a session done is a request, which can fail after the
  screen already showed it.

Writing those answers with `useState` and `useEffect` in every screen is how apps end up with a loading
flag that never clears, a request fired twice on every render, and a list that shows yesterday's data
after a change. **TanStack Query** is a library that answers all four once: it fetches, caches each result
under a key, tracks how old it is, refetches when it should, and runs changes with a way back.

## Two vocabularies

| TanStack Query calls it | it is | the planner's |
|---|---|---|
| a **query** | a read, identified by a key, cached | `["plan"]`, the whole plan |
| a **mutation** | a write, run on demand, with hooks around it | marking a session done |
| **invalidation** | marking a cached query stale so it is fetched again | after every mutation |
| **stale time** | how long a result counts as fresh | 30 seconds |

## What stays the same

The screens. Lesson 9 gave them `usePlan()`, which returns `{ plan, dispatch }`. This lesson keeps that
hook and changes what is behind it, from a reducer in memory to a query and a mutation, and **not one
screen file changes**. That is what a hook as a boundary buys: the screens ask for the plan and for
changes, and never learn where either goes.

The offline story told here is the short one, a request that waits for the network. The `mobile-offline`
course, which every student takes after this one, is about the long one: a database on the phone, a queue
of changes, and what to do when two of them disagree.
