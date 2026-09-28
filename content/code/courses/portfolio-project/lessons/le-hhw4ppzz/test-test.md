---
title: What test test says
version: 1
---

Here is loanbook the way it looks after the most common kind of manual test: a few items added in a
hurry, and one loan to whoever came to mind:

```
ana@laptop:~/loanbook$ python3 app.py add test; python3 app.py add asdf; python3 app.py add "item 3"
added test
added asdf
added item 3
ana@laptop:~/loanbook$ sqlite3 loanbook.db "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (2, 'test test', date('now'), date('now', '+7 days'))"
ana@laptop:~/loanbook$ sqlite3 -header -column loanbook.db 'SELECT i.name, l.borrower FROM items i LEFT JOIN loans l ON l.item_id = i.id'
name    borrower 
------  ---------
test             
asdf    test test
item 3           
```

Nothing here is broken, and everything here is wrong for a demo. **A screenshot of this shows nothing**:
there is no overdue loan, no second loan refused, no sense of what the page is for. **A reviewer reading it
learns the project was never used as its users would use it.** And it hides real problems: a list of
three items never shows how the page behaves with forty, or with a name longer than one word.

The fix is not to type more carefully each time. It is to write the data down once, as code, so the same
believable week appears every time the project is set up: on your machine, on the server of lesson 15,
in the screenshot and in the video. That code is a **seed script**.
