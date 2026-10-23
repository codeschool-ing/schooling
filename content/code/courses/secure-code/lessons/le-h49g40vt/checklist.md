---
title: A checklist that fits on one screen
version: 1
---

A checklist is useful when it is short enough to be used on every review and specific enough to
change what the reviewer looks at. **Long security checklists are read once and filed.** This one has
one line per lesson of the course that a diff can show, in the order of the five questions:

| look for | the question | lesson |
|---|---|---|
| a new route or action | is there a check of who, and of whose? | 1, 12, 13 |
| a value from a request | validated at one boundary, against an allowlist? | 2 |
| a record built from a request | built from known fields only? | 3 |
| a value written into a page | escaped by the template, quoted, never marked `safe`? | 4 |
| a session or cookie change | flags kept, lifetime short, ended on sign-out? | 10 |
| a password or a token | hashed or compared with the right tool? | 11 |
| an error or log line | does it reveal anything a stranger should not see? | 15 |
| a key, a password or a URL with credentials | is it in the code or the repository? | 16 |
| `requirements.txt` | pinned, and audited? | 17 |
| any of the above | did a test come with it? | 19 |

Two things a checklist cannot do. It cannot find a flaw nobody has listed, which is what the five
questions of the first section are for. And it cannot replace knowing the system: a reviewer who
knows that messages belong to patients sees finding 1 at once, and one who does not sees a route
that works.

### What a machine can take off the list

Some lines of the table can be checked without a person: a pin that became a range, a known
advisory against a version, a string that looks like a key, a template marked `safe`. Lesson 19
turns those into automated checks that run before a review starts, so the reviewer's half hour
goes on the questions only a person can answer: who may do this, and whose is it.
