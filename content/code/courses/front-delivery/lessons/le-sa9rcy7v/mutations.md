---
title: Mutations
version: 1
---

**A mutation is a request to change something, written like a query and answered like one: with the
fields you choose of what was changed.** The schema's `Mutation` type lists every change a client may
ask for, and nothing outside that list can be changed through GraphQL at all.

```
ana@dev:~/planner$ node api/ask.mjs 'mutation MarkDone($id: Int!) { markDone(id: $id) { id done course { title } } }' '{"id": 5}'
{
  "data": {
    "markDone": {
      "id": 5,
      "done": true,
      "course": {
        "title": "HTML and CSS"
      }
    }
  }
}
```

Session 5 was planned and is now done, and the answer says so in the same request. **Returning the
changed object is the convention**, and it is what lets a client update its screen without asking again:
lesson 10's clients take a mutation's answer and put it into their cache, and every part of the page that
shows session 5 updates.

## An input type

`addSession` takes one argument of the `NewSession` input type, and its variable is declared with that
type:

```
ana@dev:~/planner$ node api/ask.mjs 'mutation AddSession($input: NewSession!) { addSession(input: $input) { id date minutes done } }' '{"input": {"course": "git", "date": "2026-10-20", "minutes": 30}}'
{
  "data": {
    "addSession": {
      "id": 7,
      "date": "2026-10-20",
      "minutes": 30,
      "done": false
    }
  }
}
```

The new session got id 7, the next free one, and starts as not done. `graphql` checked the value against
`NewSession` before the function ran: a `minutes` of `"thirty"` would be refused with a message that says
so, and a missing `date` likewise.

## The server's memory

The server keeps its sessions in memory. Ask for the course again and the new session is there; restart
the server and it is gone, back to the six in `courses.json`:

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "git") { minutesPlanned } }'
{
  "data": {
    "course": {
      "minutesPlanned": 60
    }
  }
}
```

Thirty minutes from session 3, and thirty from the one just added.

## Queries read, mutations write

The difference between `query` and `mutation` is a promise rather than a mechanism: a server could change
data inside a query field, and nothing in GraphQL would stop it. What the specification does define is
that the top-level fields of a query may run in parallel, while those of a mutation run one after
another, in the order written. Two `markDone`s in one mutation are applied first to last.
