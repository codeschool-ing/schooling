---
title: "Side effects at the edges: a functional core in an imperative shell"
version: 1
---

**A program with no side effects does nothing useful.** It cannot read a request, save a loan or
send a reminder. So the functional idea is not to remove effects, which is impossible, but to
decide where they live. Gary Bernhardt's name for the arrangement, from a 2012 talk called
*Boundaries*, is **functional core, imperative shell**: the decisions are made by pure functions in
the middle, and a thin outer layer does all the reading, writing and asking the clock.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-shell\" aria-label=\"A functional core inside an imperative shell. The outer box, the shell, holds the effects: on the left, loading the loans and reading the date from the command line or the clock; on the right, writing outbox.txt and printing a summary. Arrows carry the loans and the date into the inner box, the core, which holds the pure functions notices and days_late and returns a list of Notice values. An arrow carries the notices back out to the shell, which writes them. Beneath the shell: effects, few decisions. Beneath the core: decisions, no effects.\"><defs><marker id=\"l15-shell-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"262.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"6 4\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">imperative shell: shell.py</text><rect x=\"250.0\" y=\"70.0\" width=\"220.0\" height=\"150.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">functional core: core.py</text><text x=\"360.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notices(loans, today)</text><text x=\"360.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">days_late(loan, today)</text><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ list[Notice]</text><text x=\"360.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">decisions, no effects</text><rect x=\"45.0\" y=\"87.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load the loans</text><rect x=\"45.0\" y=\"157.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">date: argv or the clock</text><path d=\"M215.0 105.0 L250.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><path d=\"M215.0 175.0 L250.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><rect x=\"505.0\" y=\"87.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write outbox.txt</text><rect x=\"505.0\" y=\"157.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">print a summary</text><path d=\"M470.0 140.0 L505.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><path d=\"M470.0 150.0 L505.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-shell-dp-ah-paper-dim)\"></path><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">effects, few decisions</text></svg>", "caption": "The core is tested with plain values; the shell is thin enough to check by running it once."}
```

## The core decides

The library's overdue notices again, split along that line. The core takes loans and a date and
returns the notices that should be sent. It sends nothing:

```schooling-example
{"language": "python", "file": "core.py", "parts": [
 {"code": "# core.py\nfrom dataclasses import dataclass\nfrom datetime import date\n\nDAILY_FINE = 50  # cents", "note": "No `sys`, no `open`, no `date.today()`. The imports alone say this module touches nothing outside itself."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    member: str\n    email: str\n    title: str\n    due: date\n\n\n@dataclass(frozen=True)\nclass Notice:\n    to: str\n    text: str", "note": "A notice is a value: who it is for and what it says. Deciding to send one and sending it are now two different things."},
 {"code": "\n\ndef days_late(loan: Loan, today: date) -> int:\n    return max((today - loan.due).days, 0)", "note": "Today is an argument. The core never asks what day it is."},
 {"code": "\n\ndef notices(loans: list[Loan], today: date) -> list[Notice]:\n    out = []\n    for loan in loans:\n        late = days_late(loan, today)\n        if late > 0:\n            text = f\"{loan.member}, '{loan.title}' is {late} days late: {late * DAILY_FINE} cents so far\"\n            out.append(Notice(loan.email, text))\n    return out", "note": "A loop that appends to a local list, and still pure: `out` is born inside the call and handed back. Nobody outside saw it change."}
]}
```

## The shell does

The shell is everything the core refused to do: it loads the loans, reads the date, writes the
outbox and talks to the user. It has no decisions of its own.

```schooling-example
{"language": "python", "file": "shell.py", "parts": [
 {"code": "# shell.py\nimport sys\nfrom datetime import date\n\nfrom core import Loan, notices", "note": "The shell imports the core. The core never imports the shell, which is the direction that keeps it pure."},
 {"code": "\n\ndef load_loans() -> list[Loan]:\n    return [Loan(\"Bia\", \"bia@example.org\", \"Dom Casmurro\", date(2026, 3, 16)),\n            Loan(\"Caio\", \"caio@example.org\", \"Iracema\", date(2026, 3, 30)),\n            Loan(\"Duda\", \"duda@example.org\", \"Vidas Secas\", date(2026, 3, 18))]", "note": "Standing in for a database query, which would be an effect too. In lesson 12 this was a repository."},
 {"code": "\n\ndef main() -> None:\n    today = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date.today()\n    outbox = notices(load_loans(), today)\n    with open(\"outbox.txt\", \"w\") as f:\n        for n in outbox:\n            f.write(f\"To: {n.to}\\n{n.text}\\n\\n\")\n    print(f\"{len(outbox)} notices written to outbox.txt for {today}\")", "note": "Read, decide, write: three lines with the core in the middle. The clock is read here and only here, and a date on the command line overrides it, which is how the run below is repeatable."},
 {"code": "\n\nif __name__ == \"__main__\":\n    main()"}
]}
```

```
ana@laptop:~/patterns/functional$ python3 shell.py 2026-03-20
2 notices written to outbox.txt for 2026-03-20
ana@laptop:~/patterns/functional$ cat outbox.txt
To: bia@example.org
Bia, 'Dom Casmurro' is 4 days late: 200 cents so far

To: duda@example.org
Duda, 'Vidas Secas' is 2 days late: 100 cents so far
```

On 20 March, Bia is four days past 16 March and Duda two days past the 18th; Caio's book is not due
until the 30th and gets nothing.

## What the split buys

The core is where the logic is, so that is where the tests go, and they need nothing:

```python
# test_core.py
import unittest
from datetime import date

from core import Loan, Notice, notices

BIA = Loan("Bia", "bia@example.org", "Dom Casmurro", date(2026, 3, 16))


class NoticesTest(unittest.TestCase):
    def test_a_late_loan_gets_a_notice(self):
        self.assertEqual(notices([BIA], date(2026, 3, 20)),
                         [Notice("bia@example.org", "Bia, 'Dom Casmurro' is 4 days late: 200 cents so far")])

    def test_nothing_is_due_yet(self):
        self.assertEqual(notices([BIA], date(2026, 3, 16)), [])
```

```
ana@laptop:~/patterns/functional$ python3 -m unittest -v test_core.py
test_a_late_loan_gets_a_notice (test_core.NoticesTest.test_a_late_loan_gets_a_notice) ... ok
test_nothing_is_due_yet (test_core.NoticesTest.test_nothing_is_due_yet) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

No fake mail server, no temporary file, no patched clock. **The shell is left with so little logic
that it can be checked by running it once**, which is what the transcript above did. Compare lesson
13's `remind`, which took a `send` function so a test could intercept the sending. That design
injects the effect; this one returns a description of the effect and lets the caller perform it.
Both are honest. Returning values is simpler when the core's job ends in a decision, and injection
is needed when the core has to act in the middle of its work, say to read one record depending on
another.

The same shape has other names you may meet. Ports and adapters, from lesson 4, puts the domain in
the middle and the I/O at the edge for a structural reason; the functional core puts it there for a
reason about purity, and they arrive at very similar code.
