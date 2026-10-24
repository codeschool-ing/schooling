---
title: Queries
version: 1
---

**A query is a tree of fields, starting from a field of `Query`, and the answer is the same tree with the
values filled in.** Every field on an object must be chosen; a field that is an object needs its own
braces, down to scalars. Nothing comes back that was not asked for.

## Fields, and fields inside fields

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "javascript") { title minutesPlanned sessions { date minutes done } } }'
{
  "data": {
    "course": {
      "title": "JavaScript",
      "minutesPlanned": 145,
      "sessions": [
        {
          "date": "2026-10-06",
          "minutes": 40,
          "done": true
        },
        {
          "date": "2026-10-12",
          "minutes": 60,
          "done": true
        },
        {
          "date": "2026-10-15",
          "minutes": 45,
          "done": false
        }
      ]
    }
  }
}
```

Three things in one request: the course, a number the server worked out, and the sessions inside it.
`course(id: "javascript")` passes an **argument** to the field, which the server's `course` function
receives as `{ id }`. The fields come back in the order they were asked for.

## Walking the graph

The schema joins `Session` back to `Course`, so a query can go round in a circle, and the server follows
it as far as asked:

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "git") { sessions { date course { title } } } }'
{
  "data": {
    "course": {
      "sessions": [
        {
          "date": "2026-10-08",
          "course": {
            "title": "Git"
          }
        }
      ]
    }
  }
}
```

That is the *graph* in the name: types joined by fields, which a query walks in any direction the schema
allows. It is also why a public server limits a query's depth: nothing in the language stops a query from
nesting `course { sessions { course { sessions … } } }` a hundred levels down.

## Aliases

A field can be asked for twice, with different arguments, if each one gets a name of its own, an
**alias**, which is what the answer uses as the key:

```
ana@dev:~/planner$ node api/ask.mjs '{ js: course(id: "javascript") { minutesPlanned } git: course(id: "git") { minutesPlanned } }'
{
  "data": {
    "js": {
      "minutesPlanned": 145
    },
    "git": {
      "minutesPlanned": 30
    }
  }
}
```

## A course that is not there

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "rust") { title } }'
{
  "data": {
    "course": null
  }
}
```

`course` has no `!` in the schema, so an unknown id answers `null` and no error. The page that asked has
to treat `null` as a real answer, the way the planner already shows its *not found* page when no course
matches the address.
