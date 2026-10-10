---
title: State versus history
version: 1
---

**Most programs store the current state and throw away how it was reached; event sourcing stores
how it was reached and treats the current state as something to work out.** Every change becomes an
event, a fact in the past tense, appended to a list that is never edited. The state of a member,
a loan or a shelf at any moment is whatever those events add up to.

The idea people bring is that an event log is an audit trail, kept beside the real data in case
somebody asks. In event sourcing the log *is* the real data. There is no table of balances to
disagree with it; a balance shown on a screen was computed from the events a moment ago, and can be
computed again.

Make `~/patterns/events` and work there for the whole lesson:

```sh
mkdir -p ~/patterns/events
cd ~/patterns/events
```

## A balance with no memory

Here is a member's fine balance kept the usual way, and the same four changes kept as history:

```python
# state_only.py
balance = {"bia": 0}

balance["bia"] += 150   # a late return
balance["bia"] += 250   # another one
balance["bia"] -= 100   # she pays at the desk
balance["bia"] += 50    # a correction nobody wrote down
print("state:", balance)

history = [
    ("2026-03-19", "CopyReturned", {"member": "bia", "copy": "C3", "fine": 150}),
    ("2026-03-23", "CopyReturned", {"member": "bia", "copy": "C1", "fine": 250}),
    ("2026-03-24", "FinePaid", {"member": "bia", "amount": 100}),
    ("2026-03-25", "FineCorrected", {"member": "bia", "amount": 50, "reason": "wrong due date on C1"}),
]
effect = {"CopyReturned": lambda d: d["fine"],
          "FinePaid": lambda d: -d["amount"],
          "FineCorrected": lambda d: d["amount"]}
owed = 0
for day, kind, data in history:
    owed += effect[kind](data)
    print(f"{day}  {kind:<13} owed {owed:>3}  {data}")
```

```
ana@laptop:~/patterns/events$ python3 state_only.py
placeholder
```

Both halves agree: Bia owes 350 cents. Only one of them can say why. The first half has a number
and four comments that exist only in the source file; at run time the library knows 350 and nothing
else. When Bia comes to the desk and asks why she owes three and a half reais, the honest answer is
"the computer says so". The second half answers line by line: two late returns, one payment, and a
correction made on 25 March because C1 had the wrong due date.

## What history buys

**Questions nobody thought of when the code was written.** "How much did members pay in fines in
March?" is a sum over `FinePaid` events. With only balances, it was never recorded, and no amount
of later code can recover it.

**The state at any moment.** Stop adding at 24 March and the history says she owed 300 then. A
table of current balances has overwritten that number for good.

**Corrections that stay visible.** The 50-cent correction is an event of its own, with a reason.
Fixing a balance in place would erase the mistake and the fix together, and the next person to look
would see a number with no story.

This is how accountants have worked for centuries, and the comparison is exact: a ledger is
append-only, a wrong entry is corrected by a new entry, and the balance is the sum of the lines.
Lesson 8 already had the write model publish events; event sourcing keeps those events as the only
record, and the rest of this lesson builds what that requires: a store that refuses edits, a way to
rebuild state, read models fed from the history, and a plan for the day the events have to change
shape.
