---
title: "The safety net: characterisation tests"
version: 1
---

**Refactoring needs tests, and the code that most needs refactoring is the code that has none.**
The way out of that circle is a different kind of test. A characterisation test, a name Michael
Feathers gave in *Working Effectively with Legacy Code* (2004), does not say what the code should
do. It records what the code *does* today, right or wrong, so that any change to it shows up as a
failure.

Make `~/patterns/refactoring` and work there:

```sh
mkdir -p ~/patterns/refactoring
cd ~/patterns/refactoring
```

## The file everybody avoids

The library prints a monthly report of late loans. It was written in a hurry years ago, works, and
is the kind of file people edit by adding one more `elif`. Save it as `report.py`:

```python
# report.py
from datetime import date, timedelta

LOANS = [
    ("Bia Souza", "+55 11 5550-0142", "bia@example.org", "Dom Casmurro", "book", date(2026, 3, 2), date(2026, 3, 20)),
    ("Caio Lima", "+55 11 5550-0177", "caio@example.org", "Central do Brasil", "film", date(2026, 3, 9), None),
    ("Bia Souza", "+55 11 5550-0142", "bia@example.org", "Iracema", "book", date(2026, 3, 10), date(2026, 3, 21)),
    ("Duda Alves", "+55 11 5550-0193", "duda@example.org", "Cidade de Deus", "film", date(2026, 3, 1), date(2026, 3, 12)),
]


def report(loans, today):
    out = []
    total = 0
    for l in loans:
        if l[4] == "book":
            due = l[5] + timedelta(days=14)
        elif l[4] == "film":
            due = l[5] + timedelta(days=7)
        else:
            due = l[5]
        if l[6]:
            end = l[6]
        else:
            end = today
        d = (end - due).days
        if d > 0:
            f = d * 50
            total = total + f
            if l[4] == "book":
                what = "book"
            elif l[4] == "film":
                what = "film (DVD)"
            else:
                what = "item"
            out.append(l[0] + " <" + l[2] + ">: " + what + " '" + l[3] + "', " + str(d) + " days late, R$ "
                       + str(f // 100) + "," + str(f % 100).zfill(2))
    out.append("total: R$ " + str(total // 100) + "," + str(total % 100).zfill(2))
    return "\n".join(out)


if __name__ == "__main__":
    print(report(LOANS, date(2026, 3, 31)))
```

```
ana@laptop:~/patterns/refactoring$ python3 report.py
Bia Souza <bia@example.org>: book 'Dom Casmurro', 4 days late, R$ 2,00
Caio Lima <caio@example.org>: film (DVD) 'Central do Brasil', 15 days late, R$ 7,50
Duda Alves <duda@example.org>: film (DVD) 'Cidade de Deus', 4 days late, R$ 2,00
total: R$ 11,50
```

The output is correct. Bia's *Dom Casmurro* was due on 16 March and came back on the 20th: four
days, 200 cents. Caio's film is still out, fifteen days past its 7-day loan on 31 March. *Iracema*
came back early and is not listed. Every smell in the previous section's table is in this one
function, and the rest of the lesson removes them one at a time.

## Pin the output down

The cheapest net for a function that produces text is the text itself. Save what it prints today
as the approved output; from now on, the test is that it still prints exactly that. The approach
has several names: golden master, snapshot, approval test.

```
ana@laptop:~/patterns/refactoring$ python3 report.py > approved.txt
```

The report for March covers the main path, but not every branch. A month in which nobody is late
takes a different route through the function, and you may not know what it prints. **Feathers'
trick is to ask the code**: write the assertion with an answer you know is wrong, and let the
failure tell you the real one.

```python
# test_report.py
import unittest
from datetime import date
from pathlib import Path

from report import LOANS, report

ON_TIME = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Vidas Secas", "book", date(2026, 3, 2), date(2026, 3, 16))]


class ReportCharacterisation(unittest.TestCase):
    def test_the_march_report(self):
        approved = Path("approved.txt").read_text()
        self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)

    def test_a_month_with_nobody_late(self):
        self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "")


if __name__ == "__main__":
    unittest.main()
```

The `+ "\n"` is there because `print` added a newline when the approved file was written, and
`report` returns the text without one.

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest -v test_report.py
test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late) ... FAIL
test_the_march_report (test_report.ReportCharacterisation.test_the_march_report) ... ok

======================================================================
FAIL: test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/refactoring/test_report.py", line 17, in test_a_month_with_nobody_late
    self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "")
AssertionError: 'total: R$ 0,00' != ''
- total: R$ 0,00


----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
```

The empty string was a guess, and the failure corrects it: a month with nobody late still prints a
total of `R$ 0,00`. Copy what the code said into the test:

```python
# test_report.py
import unittest
from datetime import date
from pathlib import Path

from report import LOANS, report

ON_TIME = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Vidas Secas", "book", date(2026, 3, 2), date(2026, 3, 16))]


class ReportCharacterisation(unittest.TestCase):
    def test_the_march_report(self):
        approved = Path("approved.txt").read_text()
        self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)

    def test_a_month_with_nobody_late(self):
        self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "total: R$ 0,00")


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest -v test_report.py
test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (test_report.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## What a characterisation test promises, and what it does not

It promises that the behaviour you recorded has not changed. **It does not promise that the
behaviour is right.** Whether a month with nobody late should print a zero total is a question for
the librarians. If the answer is no, that is a behaviour change: it gets its own test, its own
commit and its own review, and it never rides along inside a refactoring.

The net is also only as wide as the cases it holds. Two tests here cover the late path, the
early-return path and the empty month. They do not cover a kind of item that is neither book nor
film, so a refactoring that broke the `else` branches would pass. Before moving code that a test
does not reach, add a case that reaches it, or accept the risk knowingly.

Notice too what the tests call: `report(rows, today)` with plain tuples, the way the rest of the
library's code calls it. That is the interface the refactorings must keep, whatever happens inside
the file.
