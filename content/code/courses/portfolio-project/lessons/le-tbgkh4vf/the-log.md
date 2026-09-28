---
title: Where the unexpected goes
version: 1
---

The last row of the table, *something nobody expected*, has no sentence for the user. It has a line in
the server's log, and the log is part of the product as much as the page is.

loanbook writes one line per request, with the method, the path and the status it answered:

```
ana@laptop:~/loanbook$ cat app.log
loanbook on http://127.0.0.1:8000
GET /api/nothing 404
POST /api/items/1/loan 400
POST /api/items/9/loan 404
POST /api/items/1/loan 400
POST /api/items/1/loan 201
POST /api/items/1/loan 409
POST /api/items/1/return 200
POST /api/items/1/return 409
```

That is eight requests and eight lines, and a person reading it after a complaint can see exactly what
happened: two bad requests, one unknown item, one loan, one refusal, one return, and one return that
was refused. The line is written by `log_message`, which loanbook overrides so that each request is one
line with the status at the end, instead of the library's default with the date and the client's address.

Three rules for what a portfolio project's log says:

- **One line per event, the same shape every time**, so it can be searched with `grep` and read by a
  tool later, lesson 15.
- **Enough to find the request, and no more.** The path and the status, yes. The body of the request,
  no: it holds people's names, and a log is kept longer and read by more people than a database.
- **A traceback for the unexpected, never for the expected.** The log at step 7 had a traceback for a
  bad body, which was a user's mistake dressed as a crash. After step 8, a traceback in the log means
  a bug, and a log where a traceback means a bug is a log somebody will actually read.
