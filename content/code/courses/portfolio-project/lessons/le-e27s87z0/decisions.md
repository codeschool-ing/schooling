---
title: The decisions, with their costs
version: 1
---

The section that does the most for a portfolio is the one most READMEs do not have. It is where lesson
1's second proof, *you can decide*, becomes something a reviewer can read:

```
ana@laptop:~/loanbook$ sed -n '/^## Decisions/,/^## Not yet/p' README.md
## Decisions

- **The database refuses a second loan, not the code.** A partial unique
  index allows one open loan per item, so two people pressing Lend at the same
  moment cannot both succeed. A check in Python would read "available" twice
  and write two loans.
- **SQLite, not a database server.** One room, a few dozen items, one server:
  a file is enough, and a backup is a copy of it. If several schools shared
  one instance, this is the first thing to change.
- **No accounts.** The borrower is a name typed in. Everybody who uses it works
  in the same building, and a login would have doubled the first version. The
  cost is that anybody who can open the page can lend.
- **The standard library only.** Nothing to install or upgrade; the price is
  about fifteen lines of routing written by hand.

## Not yet
```

Four decisions, and every one has the same three parts. **What was decided**, in bold, as the first
words. **Why**, in terms of this project's facts: one room, a few dozen items, one server, everyone in the
same building. **What it costs**, or when it would stop being right: *if several schools shared one
instance, this is the first thing to change*; *anybody who can open the page can lend*.

The third part is the one lesson 6 insisted on, and it is the one that makes the section credible. A list
of choices with only reasons reads as a list of things you like. With their costs, it reads as
judgement, because it shows you knew what you were giving up.

Two or four decisions is the right number. Pick the ones a reviewer would otherwise ask about: the
unusual choice, *no framework*; the one with a visible limit, *SQLite*; the one that looks like a gap,
*no accounts*; and the one that is the point of the project, *the database refuses*. Each is also a
question you are now ready for in lesson 20, because you wrote the answer before anybody asked.
