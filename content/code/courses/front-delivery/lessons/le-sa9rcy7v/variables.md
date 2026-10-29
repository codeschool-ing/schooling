---
title: Variables and operation names
version: 1
---

**A query written once and filled in with variables is how an app sends GraphQL; a query built by pasting
values into a string is a bug waiting for a quote.** The query declares what it takes, with types, and
the values travel beside it in the request.

```
query CourseSessions($id: ID!) {
  course(id: $id) {
    title
    sessions {
      date
      minutes
    }
  }
}
```

- **`query CourseSessions`** gives the operation a name. The server's log prints it, a browser's network
  panel shows it, and lesson 11's error reports carry it, so *CourseSessions failed* says more than
  *a query failed*.
- **`($id: ID!)`** declares a variable, its type, and that it is required. The server checks the value
  against that type before anything runs.
- **`course(id: $id)`** uses it.

```
ana@dev:~/planner$ node api/ask.mjs 'query CourseSessions($id: ID!) { course(id: $id) { title sessions { date minutes } } }' '{"id": "html-css"}'
{
  "data": {
    "course": {
      "title": "HTML and CSS",
      "sessions": [
        {
          "date": "2026-10-05",
          "minutes": 50
        },
        {
          "date": "2026-10-14",
          "minutes": 25
        }
      ]
    }
  }
}
```

The server's log still says `(anonymous)` for it. The name inside the query is enough for `graphql` to
run it; what the server logs is the request's own `operationName` field, which `ask.mjs` leaves out. The
planner's client, later in the lesson, sends both.

## A missing variable

```
ana@dev:~/planner$ node api/ask.mjs 'query CourseSessions($id: ID!) { course(id: $id) { title } }'
{
  "errors": [
    {
      "message": "Variable \"$id\" has invalid value: Expected a value of non-null type \"ID!\" to be provided.",
      "locations": [
        {
          "line": 1,
          "column": 22
        }
      ]
    }
  ]
}
```

Nothing ran: the server refused the request because a required variable had no value, and said which.

## Why not build the string

``{ course(id: "${id}") { title } }`` looks shorter, and it goes wrong the first time a value holds a
quote or a brace, which a course title typed by a person eventually will. A value pasted into the query
can also change what the query asks for, the same mistake as building SQL from strings. With variables
the query text never changes, so it can be written once, checked once by the test at the end of this
lesson, and recognised by name in every log.
