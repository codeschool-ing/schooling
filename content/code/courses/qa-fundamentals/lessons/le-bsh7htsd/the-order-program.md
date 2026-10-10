---
title: The program that places orders
version: 1
---

**`tickets.py` answers what one ticket costs. Selling tickets also needs an order**: several tickets for
one session, a total, and a record that the sale happened. Rafael wrote that part too, and it is the first
program in the course that keeps something after it finishes. Save it in `~/aurora` as `orders.py`.

```schooling-example
{"language": "python", "file": "orders.py", "parts": [{"code": "# orders.py\nimport sqlite3\nimport sys\nfrom tickets import brl, price\n", "note": "An order uses the price rule from `tickets.py` for each ticket, and `sqlite3`, Python’s own database, to keep a record of it. Keep it in `~/aurora` beside `tickets.py`."}, {"code": "\ndb = sqlite3.connect(\"aurora.db\", isolation_level=None)\ndb.execute(\"CREATE TABLE IF NOT EXISTS orders\"\n           \" (id INTEGER PRIMARY KEY, session TEXT, tickets INTEGER, total INTEGER)\")\n", "note": "The database is one file, `aurora.db`, with one table, `orders`: a number, the session, how many tickets and the total in centavos. `isolation_level=None` makes every statement save at once."}, {"code": "\n\ndef place(day, time, ages):\n    cur = db.execute(\"INSERT INTO orders (session, tickets, total) VALUES (?, ?, 0)\",\n                     (f\"{day} {time}\", len(ages)))\n", "note": "Placing an order starts by writing its row, with a total of zero to be filled in below."}, {"code": "    if not 1 <= len(ages) <= 6:\n        return \"refused: an order holds 1 to 6 tickets\"\n", "note": "The rule’s fourth sentence: an order holds between one and six tickets. Anything else is refused."}, {"code": "    total = sum(price(age, False, day, time) for age in ages)\n    db.execute(\"UPDATE orders SET total = ? WHERE id = ?\", (total, cur.lastrowid))\n    return f\"order {cur.lastrowid}: {len(ages)} tickets, {brl(total)}\"\n", "note": "Otherwise the price of each ticket is added up and written into the row. This version sells no student tickets: `False` is passed for every one, and Joana has scheduled students for later."}, {"code": "\n\nif __name__ == \"__main__\":\n    day, time = sys.argv[1], sys.argv[2]\n    print(place(day, time, [int(a) for a in sys.argv[3:]]))\n", "note": "On the command line: the day, the time, and then the age of each person, one word per ticket."}]}
```

## Placing orders from the outside

The command takes the day, the time, and one age per ticket. A family of two adults and a child on a
Thursday evening, and two adults at a Saturday matinée:

```
lia@lab:~/aurora$ python orders.py thu 20:00 35 35 8
order 1: 3 tickets, R$ 90,00
lia@lab:~/aurora$ python orders.py sat 15:00 35 35
order 2: 2 tickets, R$ 56,00
```

Both answers are right by the rule. Two adults at R$ 36,00 and a child at R$ 18,00 make R$ 90,00; two
adults at a matinée make R$ 56,00. The order numbers count up from one. From the outside, the program does
what it should.

## And from the inside

A grey-box tester does not stop at what the program printed, because the program also wrote something.
Python's `sqlite3` module has a command line of its own that runs one query against a database file and
prints the rows. Here is everything in the `orders` table:

```
lia@lab:~/aurora$ python -m sqlite3 aurora.db "SELECT * FROM orders"
(1, 'thu 20:00', 3, 9000)
(2, 'sat 15:00', 2, 5600)
```

Each row is a tuple: the order number, the session, the number of tickets and the total in centavos. They
agree with what the screen said: 9000 centavos is R$ 90,00, and 5600 is R$ 56,00. **The outside and the
inside tell the same story**, which is what a grey-box check is for: confirming that what the user was told
is what the system recorded.

That agreement is not automatic. A program can print one total and store another, because printing and
storing are two separate lines that can go wrong separately. When they agree, the test has checked
something black box could not. The next section is about when they do not.
