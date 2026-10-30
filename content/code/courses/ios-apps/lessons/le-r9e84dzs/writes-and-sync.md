---
title: Writing on the device, and sending later
version: 1
---

**A write that waits for the server is a write that fails on the train.** So the repository's `add`
does the opposite of what lesson 12's `fetch` did: it puts the session on the device, in the list of
pending sessions, saves the file, and only then tries to send it. If the send works, the session
moves from pending to confirmed. If it does not, the session stays pending and the person sees it in
their plan anyway.

The repository's second half, in section 04's listing, is those two methods. `add` checks the
session against the plan the device has, appends it to `pending`, saves, and calls `sync`. `sync`
walks the pending list and sends each session. **The list is the promise**: as long as a session is
in it, the device has not been told the server has it.

## Adding with no server

The server is still stopped from section 04. Add a session:

```
ana@vm:~/planner$ .build/debug/repo add s5 mobile 2026-10-22 30
added s5 on the device
2 courses, 5 sessions, 1 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 180, done: 90)
ana@vm:~/planner$ grep -A8 "\"pending\"" planner.json
  "pending" : [
    {
      "courseId" : "mobile",
      "date" : "2026-10-22",
      "done" : false,
      "id" : "s5",
      "minutes" : 30
    }
  ],
```

The plan has five sessions now, one of them waiting, and the week's total already counts it: 180
minutes planned. The file says exactly what the device knows, and the `pending` list in it is the
part that matters. This is the same `courseId` spelling the server uses, because the file reuses
lesson 12's wire types.

## The network comes back

Start the server again and run `sync`. In an app this would happen on its own, when the app comes
to the foreground or the network returns; lesson 16 is about when iOS lets it happen in the
background as well.

```
ana@vm:~/planner$ .build/debug/repo sync
synced
2 courses, 5 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 180, done: 90)
```

**Nothing is waiting, and the server's terminal shows the `POST /sessions` that brought it**: the
session the device had kept arrived. The plan did not change, because from the person's side
nothing happened: the session was in the plan before, and it is in the plan now.

## Two writes that are not the same mistake

Not every failed send should be kept. The `catch` in `sync` tells two kinds apart:

| what came back | what it means | what `sync` does |
|---|---|---|
| `offline`, `cancelled`, or a `5xx` | the server did not take it this time | keeps it pending, to try again |
| a `4xx`, like `422 no course art` | the server will never take it | drops it, and returns its id |

A session the server refuses for good would otherwise sit in `pending` for ever and be sent on every
sync, and the person would see it in a plan where it can never be confirmed. Returning its id is how
the screen finds out and can say so. Section 07 makes both cases happen.
