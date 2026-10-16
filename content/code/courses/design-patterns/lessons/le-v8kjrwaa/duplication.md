---
title: "Duplication: one piece of knowledge, one place"
version: 1
---

**Duplicated code is dangerous because of the change that updates one copy and not the other**, not
because it takes up space. `report` formats money twice, once for each line and once for the
total, with the same expression: `str(f // 100) + "," + str(f % 100).zfill(2)`. The day the library
decides to print `R$ 1.150,00` with a thousands separator, somebody will fix the line that
complained and leave the other printing the old way.

The cure is the move from the previous section applied to the copies: extract the expression into a
function, then replace each copy with a call. While the file is open, the bare `50` gets a name as
well, since it is a fact about the library that a reader should not have to guess:

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]\nDAILY_FINE = 50  # cents", "note": "The fine per day, named once. The comment gives the unit, which the next section turns into a type."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on\n\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"\n\n\ndef days_late(row, today):\n    end = row[6] or today\n    return (end - due_date(row[4], row[5])).days", "note": "Unchanged since the previous section."},
 {"code": "\n\ndef money(cents):\n    return f\"R$ {cents // 100},{cents % 100:02d}\"", "note": "The one place that knows how the library writes an amount. `:02d` pads the cents to two digits, which is what `zfill(2)` did."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = 0\n    for l in loans:\n        d = days_late(l, today)\n        if d > 0:\n            f = d * DAILY_FINE\n            total = total + f\n            out.append(f\"{l[0]} <{l[2]}>: {label(l[4])} '{l[3]}', {d} days late, {money(f)}\")\n    out.append(f\"total: {money(total)}\")\n    return \"\\n\".join(out)", "note": "Both copies now call `money`. The concatenation became an f-string, a separate small move made while the line was being touched anyway, with a test run after it."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

## The net earns its keep

Suppose that while writing `money` you had dropped the padding, which is easy to do when converting
`zfill` into an f-string:

```python
    return f"R$ {cents // 100},{cents % 100}"
```

This time the file runs its own tests through `unittest.main()`:

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py
FF
======================================================================
FAIL: test_a_month_with_nobody_late (__main__.ReportCharacterisation.test_a_month_with_nobody_late)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/refactoring/test_report.py", line 17, in test_a_month_with_nobody_late
    self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "total: R$ 0,00")
AssertionError: 'total: R$ 0,0' != 'total: R$ 0,00'
- total: R$ 0,0
+ total: R$ 0,00
?              +


======================================================================
FAIL: test_the_march_report (__main__.ReportCharacterisation.test_the_march_report)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/refactoring/test_report.py", line 14, in test_the_march_report
    self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)
AssertionError: "Bia [60 chars]$ 2,0\nCaio Lima <caio@example.org>: film (DVD[140 chars]50\n" != "Bia [60 chars]$ 2,00\nCaio Lima <caio@example.org>: film (DV[142 chars]50\n"
- Bia Souza <bia@example.org>: book 'Dom Casmurro', 4 days late, R$ 2,0
+ Bia Souza <bia@example.org>: book 'Dom Casmurro', 4 days late, R$ 2,00
?                                                                      +
  Caio Lima <caio@example.org>: film (DVD) 'Central do Brasil', 15 days late, R$ 7,50
- Duda Alves <duda@example.org>: film (DVD) 'Cidade de Deus', 4 days late, R$ 2,0
+ Duda Alves <duda@example.org>: film (DVD) 'Cidade de Deus', 4 days late, R$ 2,00
?                                                                                +
  total: R$ 11,50


----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=2)
```

**The approved output caught a missing zero that no reader would have spotted in review.** `R$ 2,0`
looks like a plausible way to write two reais until you put it next to `R$ 2,00`. Both tests fail,
because each report contains an amount whose cents are zero. Undo, write the `:02d`, run again:

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## Duplicated knowledge, not duplicated text

Andy Hunt and Dave Thomas put the principle as *don't repeat yourself* in *The Pragmatic Programmer*
(1999), and they were precise about it: every piece of **knowledge** should have one authoritative
representation. Text that looks alike is not always the same knowledge.

The two `if` chains in this file both test `kind == "book"` and `kind == "film"`. Are they
duplication? They encode one fact, *which kinds of item exist*, and adding a kind means editing
both, so yes, and the section on switches removes it. Compare the 14 and the 7: they look like the
same sort of number but encode two separate policies that change for separate reasons. Folding
them into one table would be fine; deriving one from the other would be a mistake.

Two practical rules keep extraction from going too far:

- **The rule of three**, which Fowler credits to Don Roberts: the first time, just write it; the
  second time, notice the copy and wince; the third time, extract. Two copies are sometimes a
  coincidence, and an abstraction made from two examples often guesses the wrong shape.
- Extract what changes together. If two copies would have to change for different reasons, they
  are two pieces of knowledge that happen to look alike, and joining them couples things that were
  independent.
