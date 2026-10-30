---
title: The API contract
version: 1
---

**Every field an old version of the app reads is a promise the server keeps for as long as that
version is in the support window.** Nobody signed it. It was made the day the version shipped,
by the code that parses the response, and that code cannot be changed any more.

## The planner's sessions, as 1.3.1 reads them

The planner asks the server for the week's study sessions. Since 1.3.1 the answer has looked like
this:

```json
[
  { "id": "s-101", "course": "statistics", "minutes": 25, "day": "2026-10-12", "status": "done" },
  { "id": "s-102", "course": "python", "minutes": 40, "day": "2026-10-13", "status": "planned" }
]
```

The 1.3.1 app reads `minutes` as a number and adds it up for the week's total, reads `day` to put
the session in its column, and draws a tick when `status` is `"done"` and an empty circle when it
is `"planned"`. Those three uses are the contract, whatever the server's own documentation says.

## Changes that keep the promise, and changes that break it

| Change on the server | 1.3.1, already installed |
| --- | --- |
| Add a field, `seconds` | ignores it, if its parser ignores fields it does not know |
| Rename `minutes` to `durationMinutes` | finds no `minutes`; the week's total is wrong or the screen fails |
| Change `minutes` from `25` to `"25"` | adds strings: `"25" + "40"` is `"2540"` in JavaScript |
| Add a status, `"skipped"` | meets a value it has no drawing for |
| Remove a session field nobody reads | nothing, if nobody really reads it |
| Make a request field required | every old version's request is refused |

**The safe changes are additions, and only additions the old versions can ignore.** Renaming is a
removal and an addition at once, and the removal is what breaks. A change of type is a removal in
disguise. A new value in a field that already exists is the one that looks additive and is not,
because the old code already decided what to do with every value it expected.

## The client's half: the tolerant reader

The server keeps the promise; the app makes it cheaper to keep, by reading tolerantly from its first
version on:

- **Ignore fields you do not know.** A strict parser that refuses an unknown field turns every
  addition into a breaking change.
- **Default what is missing.** A field that is absent gets a value that does no harm, and the screen
  still draws.
- **Have a branch for the value you have never seen.** A `status` that is neither `"done"` nor
  `"planned"` is drawn as something neutral, not as a crash. In Kotlin a `when` over a string needs
  an `else`, in Swift a `switch` over a decoded enum needs a fallback case for decoding to survive,
  and in a React Native app the `default:` of a `switch` is the same decision.

None of this lets the server break the contract; it makes the server's mistakes smaller. Lesson 19's
remote configuration is read the same way, for the same reason.

## Two ways to make a change that is not additive

1. **Version the endpoint.** `/v2/sessions` answers with the new shape and `/v1/sessions` keeps the
   old one until the last version that calls it leaves the window. Two shapes means two code paths
   to keep working, which is the cost.
2. **Expand, then contract.** Add `seconds` beside `minutes` and send both; release an app that reads
   `seconds`; wait until every version in the window reads it; only then stop sending `minutes`. It
   takes months and keeps one endpoint.

Both end the same way: an old shape is removed only when the count of the last section says nobody in
the window still reads it. The next section is the test that holds a server to that until then.
