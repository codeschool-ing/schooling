---
title: Three states a row can be in
version: 1
---

**Once the device holds the truth first, every row has a second fact about it besides its data:
whether the server has it yet.** The planner writes that fact into the row itself, in the `sync`
column, with one of three values.

| state | what it means | what the screen says |
|---|---|---|
| `pending` | written here, not yet accepted by the server | `waiting to send` |
| `synced` | the server accepted it | `saved` |
| `failed` | the server answered, and the answer was no | `not saved:` and why |

A common shortcut is one boolean, `dirty`, set on a change and cleared after a send. It cannot
tell `failed` from `pending`, so a session the server refused is retried forever and looks, to the
person, like one that is merely slow. **A refusal is an answer, and the row has to keep it.** The
`error` column holds what the server said, so the screen can repeat it.

The `check` constraint in `store.ts` matters for the same reason. A typo such as `'synched'` in
some later code would otherwise be stored, match no query, and leave a row that no screen counts
as pending and no sync ever sends.

## Sending, with and without a network

`app.ts sync offline` is the app noticing there is no network: it looks at what is pending and
leaves it so. `sync online` sends each pending row to the stand-in server, which refuses a session
longer than 240 minutes, the rule a real planner's server would hold. Add one more session, a
300-minute one, and run both:

```
ana@dev:~/planner/offline$ node app.ts add s8 statistics 2026-10-24 300
added s8
ana@dev:~/planner/offline$ node app.ts sync offline
s7: no network, still pending
s8: no network, still pending
ana@dev:~/planner/offline$ node app.ts sync online
s7: accepted
s8: refused, a session is at most 240 minutes
ana@dev:~/planner/offline$ node app.ts week 2026-10-19
2026-10-19  spanish     30 min  saved
2026-10-20  statistics  45 min  saved
2026-10-21  guitar      20 min  saved
2026-10-22  spanish     30 min  saved
2026-10-23  guitar      25 min  saved
2026-10-24  statistics 300 min  not saved: a session is at most 240 minutes
```

Three things happened, and each is worth saying out loud.

- **Offline, nothing changed.** The rows are still `pending`, which is true, and the person can keep
  working.
- **Online, `s7` became `synced`.** Its data did not change; only the fact about the server did.
- **`s8` became `failed`, and stayed on the screen.** The planner did not delete it. The session
  is the person's, typed by them, and the server's refusal does not make it disappear; it makes it
  something to fix.

## What "synced" does not promise

`synced` means the server accepted this version of the row. It does not mean the row is the same
as the server's now: another device may have changed it since. That is the subject of lessons 11
to 15, and the state above is where they start from. The next section is about the person's half
of this: what the screen says while a row is `pending`, and what it says when one becomes `failed`
an hour after the person typed it.
