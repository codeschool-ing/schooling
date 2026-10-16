---
title: Three decisions from the library, argued
version: 1
---

**A decision about a pattern is only as good as the force it names and the cost it admits.** This
section takes three requests the library really could make and argues each one through: the force
in one sentence, the candidates, what each would cost, and the choice. In every case the answer is
smaller than the most impressive candidate, and the argument says what would change that.

## Case 1: fines that differ by category and by kind of item

*The force.* Students now pay 25 cents a day and staff pay nothing; a senior category arrives next
term at 25 cents. Separately, films are to be fined at most the price of the film, because a DVD
that costs 12 reais should not run up a 15-real fine.

*The candidates.* A strategy class per category, chosen by a factory; a dictionary of rates; a
dictionary of functions.

*The argument.* The two forces are different in kind, and treating them as one is how the layered
version of the previous sections happened. The category changes **a number**, so it belongs in
data, where a new category is one line and no new code. The kind of item changes **a calculation**,
so it needs code, and lesson 15's point applies: in Python a function is already an object you can
store in a dictionary, so the strategy pattern is a dictionary of functions.

```schooling-example
{"language": "python", "file": "policies.py", "parts": [
 {"code": "# policies.py\nfrom typing import Callable\n\nDAILY_CENTS = {\"adult\": 50, \"student\": 25, \"staff\": 0, \"senior\": 25}", "note": "The category is data. A senior category was one line, and so will the next one be."},
 {"code": "\ndef daily(category: str, days_late: int, price: int) -> int:\n    return max(days_late, 0) * DAILY_CENTS[category]\n\n\ndef capped(category: str, days_late: int, price: int) -> int:\n    return min(daily(category, days_late, price), price)", "note": "The kind of item is code: two functions with the same signature. `daily` ignores `price`, which is the small cost of putting both in one family."},
 {"code": "\nRULES: dict[str, Callable[[str, int, int], int]] = {\"book\": daily, \"film\": capped}\n\n\ndef fine(kind: str, category: str, days_late: int, price: int) -> int:\n    return RULES[kind](category, days_late, price)", "note": "The strategy, in its smallest form: a dictionary from kind to function, and one function that looks it up."},
 {"code": "\nif __name__ == \"__main__\":\n    cases = [(\"book\", \"adult\", 10, 4990), (\"book\", \"student\", 10, 4990),\n             (\"film\", \"adult\", 30, 1200), (\"book\", \"staff\", 30, 4990)]\n    for kind, category, days, price in cases:\n        print(f\"{kind:<5} {category:<8} {days:>2} days late: {fine(kind, category, days, price):>4} cents\")", "note": "Four cases, with prices in cents: a 49.90 book and a 12.00 film."}
]}
```

```
ana@laptop:~/patterns/choosing$ python3 policies.py
book  adult    10 days late:  500 cents
book  student  10 days late:  250 cents
film  adult    30 days late: 1200 cents
book  staff    30 days late:    0 cents
```

The film thirty days late would have owed 1500 cents and was capped at its price, 1200. *The
choice:* a table for the rate and a dictionary of functions for the rule. *What would change it:*
if a rule needed its own configuration and state, such as a fine that grows after a warning has
been sent, a small class per rule would start to pay, and the dictionary would hold instances
instead of functions.

## Case 2: telling three parts of the system that a book came back

*The force.* When a loan is returned, the fines desk must settle the fine, the member gets an
e-mail, and the statistics count it. Next year the reservations desk will want to know too.

*The candidates.* Three calls written in a row inside `give_back`; an observer, as a list of
listeners; a message broker between processes.

*The argument.* Three calls in a row would make the loan know about e-mail and statistics, and each
new listener would mean editing the loan. That is a force, and it is the observer's exact
applicability. A broker is a different answer, to a different force: listeners in other processes,
or events that must survive a restart. Neither is true here, and a broker would add a server to run,
a format to agree on and the staleness of lesson 9.

*The choice:* an in-process list of listeners, with lesson 18's snapshot if threads are involved.
*What would change it:* the e-mail moving to a separate service, or a requirement that no return
is ever lost when the process crashes. Then the list becomes an outbox and a queue, which is
`architecture` lesson 7's subject.

## Case 3: proving when a book was returned

*The force.* A member disputes a fine and says she returned *Vidas Secas* on the 3rd. The library
can see that the loan is closed and cannot see when, or who closed it.

*The candidates.* Event sourcing for loans, as in lesson 9; an append-only table of loan events
beside the current state; a `returned_by` and `returned_at` column.

*The argument.* The force is **audit**: answering *what happened, and when*. Event sourcing answers
it, and also makes the event log the source of truth, with folding, snapshots and versioned events
to maintain. Nothing in the request asks to rebuild state from history. Two columns answer the
dispute and lose the second change if a return is ever corrected. An append-only table answers
every such question and leaves the loan model as it is.

*The choice:* an append-only `loan_events` table, written in the same transaction as the change to
the loan. *What would change it:* the library wanting to replay history into new views, such as
"how long did loans last in 2025, by branch", often enough that the current state stops being the
interesting thing. That is when lesson 9's design starts paying for its machinery.

## What the three have in common

Each decision named a force, rejected at least one bigger answer by naming its cost, and wrote down
the event that would reopen it. That last part is the one most often skipped. A choice with its
reopening condition attached is one that the next person can revisit without having to guess why it
was made, which is what section 07 turns into a document.
