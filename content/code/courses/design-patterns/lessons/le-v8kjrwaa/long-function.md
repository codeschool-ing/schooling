---
title: "Long function: extract until each piece says one thing"
version: 1
---

**A long function is rarely a problem of length.** Forty lines that do one thing in order are
fine. The problem is a function that does several jobs, so that understanding any one of them means
reading all of them, and changing one risks the others. `report` does at least four: it works out a
due date, counts days late, chooses a label for the kind of item and formats a line of text. Each
of those is a question somebody will ask on its own: *when is this film due?* has nothing to do with
how a line is punctuated.

The move is **extract function**: take a fragment that does one job, give it a name that says what
the job is, and call it from where the fragment was. Fowler's test for when to extract is not size
but intention. If you have to read a block to know what it is for, it should be a function whose
name tells you.

## Three extractions

Each of the three below was a separate move, and the tests ran after each. The file shown is after
the third:

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]", "note": "The data is untouched. Refactoring changes the code that reads it, and the callers keep passing the same tuples."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on", "note": "The first `if` chain, lifted out whole. It takes the two values it reads instead of the whole row, so its signature says what it depends on."},
 {"code": "\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"", "note": "The second chain. Its local variable was called `what`; the function's name says what `what` was."},
 {"code": "\n\ndef days_late(row, today):\n    end = row[6] or today\n    return (end - due_date(row[4], row[5])).days", "note": "Four lines of `if l[6]: ... else: ...` became `row[6] or today`. That is safe here because a date is never false; for a value that could be zero or empty it would change the behaviour."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = 0\n    for l in loans:\n        d = days_late(l, today)\n        if d > 0:\n            f = d * 50\n            total = total + f\n            out.append(l[0] + \" <\" + l[2] + \">: \" + label(l[4]) + \" '\" + l[3] + \"', \" + str(d) + \" days late, R$ \"\n                       + str(f // 100) + \",\" + str(f % 100).zfill(2))\n    out.append(\"total: R$ \" + str(total // 100) + \",\" + str(total % 100).zfill(2))\n    return \"\\n\".join(out)", "note": "What is left reads as the report's own job: for each loan that is late, add a line and a fine. The string building is still ugly; that is the next section."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

The command below is the same test run without `-v`, a dot per test. From here on the lesson uses
several equivalent ways of running the same two tests; they all run `test_report.py`.

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest test_report.py
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## Naming is the refactoring

The extraction itself is mechanical, and most editors will do it with one command. The decision
that matters is the name. **A good name removes the need to read the body**: a reader of `report`
now sees `days_late(l, today)` and moves on, which is the whole gain. A name like `helper1` or
`process_part` keeps the structure and loses the benefit.

Two signals that a block wants to be a function with a name:

- a comment above it explaining what it does. `# work out when it is due` is the name
  `due_date`, written in the wrong place;
- a blank line separating it from its neighbours, which is the author admitting it is a separate
  step.

## Every language has this move

| language | what an extracted helper usually becomes |
|---|---|
| Python | a module-level function; a leading underscore if it is private to the module |
| Java | a `private` method, or a `private static` one if it uses no fields |
| Go | an unexported, lower-case function in the same package |
| TypeScript | a function in the module that is not exported |

IDEs in all four will extract a function and work out its parameters. What none of them can do is
tell whether the result has one job and an honest name; that part is yours.

`days_late` still reaches into `row[6]` and `row[4]` by position, and nothing tells a reader what
position 4 is. That smell has a name too, and the section on primitive obsession deals with it.
