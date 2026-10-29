---
title: Lists, and objects the cache has not seen
version: 1
---

**A mutation that changes an object the cache knows updates every query on its own; a mutation that
creates one does not, because the cache cannot know which lists it belongs in.** Steps 3 and 4 are the
two cases.

## Changing a known object

```
3. Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":true}
```

The mutation asked back only `id` and `done`. Apollo read the answer, saw `__typename` `Session` and `id`
6, and wrote `done: true` into the existing `Session:6`. Every query that includes session 6 now reads it
as done, without being run again. **This is why lesson 9's convention of returning the changed object
matters**: with a client, the returned fields are the update.

## Creating a new one

```
4. Course:git sessions: [{"__ref":"Session:3"}]
5. Course:git sessions: [{"__ref":"Session:3"},{"__ref":"Session:7"}]
```

`addSession` returned session 7, and the cache stored `Session:7`. But git's list of sessions still holds
only session 3. The answer said nothing about which course's list the new session joins, or where in it,
and the cache does not guess. Step 5 asked the server again and the list came back with both.

There are three ways to bring a list up to date after a creation, from least work to most:

- **Ask again.** `refetchQueries: ["Planner"]` on the mutation runs the named query once more when the
  mutation finishes. It costs a request and is always right.
- **Return the parent.** If `addSession` returned the course with its sessions, the cache would update the
  list from that answer, as it updated `done` in step 3. That needs the schema to offer it.
- **Edit the cache.** The mutation's `update` function receives the cache and can append the new reference
  to `Course:git`'s `sessions` with `cache.modify`. No request, and code that has to know every list the
  object belongs in.

Deleting is the same problem the other way round: the object's entry can be evicted, but a list that
pointed at it has to be told. The planner never creates sessions on the server in this course; the drill
asks which of the three you would pick if it did.
