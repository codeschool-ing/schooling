---
title: Finding IDOR in code you did not write
version: 1
---

An IDOR is invisible on a screen and obvious in code, once you know the two shapes. Reviewing a
codebase for them, or your own pull request before anybody else does, is a search with three steps.

### 1. Find every query by identifier

List every place a record is fetched, changed or deleted by an id that came from the request: route
parameters such as `<int:exam_id>`, query strings, JSON fields, form fields. In a Flask application
that is the arguments of every view and every `request.args`, `request.form` and `request.json`. In
an application with an ORM it is `get(id)`, `filter_by(id=…)` and their relatives.

### 2. For each one, ask where the owner is

Read the query, or the code right after it, and find the condition that ties the record to the
signed-in person. There are three acceptable answers and one unacceptable one:

| what you find | verdict |
|---|---|
| the owner is part of the query: `WHERE id = ? AND patient = ?` | safe |
| the row is fetched, then its owner compared with the session, before anything is returned or changed | safe, and one forgotten line from unsafe |
| the record is reached through the person: `current_user.exams.get(id)` in an ORM | safe |
| nothing ties the record to the person | IDOR |

Watch the ones that **change** data with the same care as the ones that read it. A delete or an update
by id alone does damage without returning anything, so it never shows up in a response somebody
reads.

### 3. Look for owners that arrive in the request

Search for the names of owner fields in what the request carries: `patient`, `user_id`,
`account`, `owner`, `tenant`. Each one the server **uses to choose whose data to read or change** is a
finding, as `?patient=` was. A value the server only stores after setting it from the session is
fine; a value it believes is not.

### And test the grid

For every resource a person owns, one test with the shape of this lesson's last: each person asks for
each record, and only the owner gets an answer. It catches a new route that forgot the rule, a refactor
that moved the query, and an ORM call that quietly dropped a filter. **It is cheap because it does not
need to know where the flaw might be.**

### In the logs

A patient who asks for exams 1 to 400 in a minute, and gets 399 `404`s, is either a bug in an app or
somebody counting. Lesson 15 put refusals of access among the security events worth a line; the
`404`s of `own_exam` are exactly those refusals, and fifty of them from one session are worth an
alert.
