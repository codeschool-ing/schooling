---
title: Failures that cross the boundary
version: 1
---

**Between the phone and the server there are failures neither side can see whole.** The phone
knows it sent a request and got no answer. It cannot know whether the request never arrived, or
arrived, was done, and only the answer was lost. Lesson 12's cancelled requests showed the second
case from the server's side: the work was done for a client that had gone. For a read that costs
nothing. For a write it is the question this section answers.

## The answer that was lost

The test `anAnswerLostOnTheWayIsSentAgainAndKeptOnce` in section 06 is exactly this. The fake keeps
the session and then throws `timedOut`, so the repository keeps it pending, as it should: from where
it stands, nothing was confirmed. The next `sync` sends it **a second time**. That is only safe
because of a rule on the server, and lesson 12's `serve.py` follows it: **a session posted twice with
the same `id` is kept once.** The id is chosen on the device, when the session is made, so the second
post is recognisably the same session and not a new one.

Without that rule, every lost answer would become a duplicate session in the plan, and the
repository could not prevent it by being careful: being careful is waiting for an answer that will
never come. **An operation that gives the same result however many times it is repeated is called
idempotent**, and making writes idempotent is the server's half of offline-first. `mobile-offline`
lesson 10 builds the general version, the idempotency key, for requests that have no natural id.

## The write the server refuses

The second hard case is a session the device accepted and the server never will: a course deleted on
the server while the phone was away. The test `aSessionTheServerRefusesIsDroppedAndReported` gives
the device a course called `art` that the fake does not have, adds a session for it, and checks that
it comes back in the list of refused ids and leaves the plan.

The device itself refuses one step earlier when it can. Run `repo` with a course the device has never
heard of, server running or not:

```
ana@vm:~/planner$ .build/debug/repo add s6 art 2026-10-22 30
not added: unknownCourse("art")
2 courses, 5 sessions, 0 waiting to be sent
WeekTotal(monday: "2026-10-19", planned: 180, done: 90)
```

**That refusal came from lesson 1's `Plan.add`, before anything was saved or sent.** The repository
checks a write against the plan it has; only a write that passes that check reaches `pending`, and
only the server can refuse it after that.

## The failure on the device itself

The third failure is the file. A full disk or a revoked permission makes `save` throw, and an
`add` that swallowed that would tell the person a session was kept when it was not. The repository
records the error in `storeError` instead, and `repo` prints it whenever it is set. None of the runs
in this lesson printed it, because none of them failed to save; the line exists so that the day one
does, somebody is told.

| where it fails | what the repository does | what the person sees |
|---|---|---|
| the network, on a read | keeps the plan it has | the plan, and a note that it may be old |
| the network, on a write | keeps the session pending | the session, marked as not yet sent |
| the server refuses a write | drops it and returns its id | a message naming what was not kept |
| the device's own file | records `storeError` | a message that the device could not save |
