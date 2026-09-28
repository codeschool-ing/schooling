---
title: The questions loanbook should expect
version: 1
---

The questions about a project are predictable, because they come from the same places every time: the
unusual choices, the visible limits, and the part you said was hard. Here are loanbook's, with the answer
it would give, each in the shape of the first section:

```localised
Why no framework?
  Two routes and a page did not need one, and I wanted to see the HTTP layer. The cost is
  about fifteen lines of routing by hand. With more routes, or authentication, I would use one.

What happens with a thousand users?
  One process and a SQLite file handle one staffroom easily; I have not measured further.
  The first limits would be concurrent writes on SQLite and a single server. I'd move to a
  database server before anything else, and the unique index moves with it.

How would you add logins?
  Accounts, sessions and a check on every route, which is why it was cut. The borrower
  field would become the signed-in user, and the loan rule would not change.

What was the hardest part?
  Two people lending the same item at once. A check in Python reads "available" twice,
  so the database refuses instead, and I proved the test fails without the index.

What would you do differently?
  Answer unexpected errors with a 500 instead of closing the connection, and add a loading
  state. Both are in the retrospective.
```

Two things about preparing a list like this. **Write the answers down**, as here, and then say them aloud
until they come out in your own words; a memorised paragraph sounds memorised. And **check every answer
against the project**: *I have not measured further* is in the second answer because nothing was measured.
An interviewer who asks *how do you know?* should get evidence or an honest *I don't*, never a number you
invented.
