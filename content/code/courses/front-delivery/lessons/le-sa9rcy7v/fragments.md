---
title: Fragments
version: 1
---

**A fragment is a named set of fields on a type, which a query can spread wherever that type appears.**
It is GraphQL's way of not repeating yourself, and in a front-end it is more than that: it lets each piece
of the interface say which fields it needs.

The planner needs the same five things about every session wherever it gets one: the id, the date, the
minutes, whether it is done, and which course it belongs to. That is a fragment:

```
fragment SessionFields on Session {
  id
  date
  minutes
  done
  course {
    id
  }
}
```

`on Session` says which type it applies to, and the server refuses to spread it anywhere else. Spread
with `...`, it stands for its fields:

```
ana@dev:~/planner$ node api/ask.mjs 'query Planner { courses { id title sessions { ...SessionFields } } } fragment SessionFields on Session { id date minutes done course { id } }' | head -20
{
  "data": {
    "courses": [
      {
        "id": "html-css",
        "title": "HTML and CSS",
        "sessions": [
          {
            "id": 1,
            "date": "2026-10-05",
            "minutes": 50,
            "done": true,
            "course": {
              "id": "html-css"
            }
          },
          {
            "id": 5,
            "date": "2026-10-14",
            "minutes": 25,
```

The fragment is sent with the query, in the same string: the server keeps no fragments of its own, and a
query that spreads one it was not given is refused.

## One shape for the query and the mutation

The planner reads sessions with the query above and writes them with `markDone`, and both should give it
a session in the same shape, so the code that turns the answer into a `Session` is written once. Both
spread the same fragment:

```
ana@dev:~/planner$ node api/ask.mjs 'mutation MarkDone($id: Int!) { markDone(id: $id) { ...SessionFields } } fragment SessionFields on Session { id date minutes done course { id } }' '{"id": 6}'
{
  "data": {
    "markDone": {
      "id": 6,
      "date": "2026-10-15",
      "minutes": 45,
      "done": true,
      "course": {
        "id": "javascript"
      }
    }
  }
}
```

## Fragments beside components

The idea goes further in larger apps. A component that draws a session row knows which fields it draws,
so it declares a fragment next to its code, and the page's query spreads the fragments of the components
it renders. Change the row to show the course title and you change its fragment, and every query that
renders a row asks for the title from then on. **Relay is built around this rule**, called fragment
colocation, and lesson 10 shows it; Apollo supports the same habit without enforcing it.
