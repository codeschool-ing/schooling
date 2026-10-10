---
title: "MVP: a view too thin to need testing"
version: 1
---

**Model-view-presenter moves every decision about what the screen shows out of the view and into a
presenter, so that the view is left with nothing worth testing.** The view becomes passive: it
forwards what the person did to the presenter and displays what the presenter tells it to,
strings already formatted. The presenter talks to the view through an interface, which means a test
can hand it a fake view and read back every word the screen would have shown.

The name comes from Taligent, an IBM and Apple venture of the early nineties, and the form used here
is the one Martin Fowler called *passive view* in 2006. The picture to drop is "MVP is MVC with the
controller renamed". The arrows move: in MVC the view read the model directly, and in MVP **the
view never sees the model at all**.

```schooling-example
{"language": "python", "file": "mvp.py", "parts": [
 {"code": "# mvp.py\nfrom datetime import date\nfrom typing import Protocol\nfrom desk_model import Desk", "note": "The same model again."},
 {"code": "\n\nclass DeskView(Protocol):\n    def show_shelf(self, lines: list[str]) -> None: ...\n    def show_message(self, text: str, alarm: bool = False) -> None: ...", "note": "The view is described by what the presenter may ask of it: show these lines, show this message, raise the alarm or not. Nothing in the protocol mentions a desk, a loan or a date."},
 {"code": "\n\ndef money(cents: int) -> str:\n    return f\"R$ {cents // 100},{cents % 100:02d}\"", "note": "Presentation logic: 150 cents is `R$ 1,50` on this desk. It is a plain function, so it is tested by calling it."},
 {"code": "\n\nclass DeskPresenter:\n    def __init__(self, desk: Desk, view: DeskView, today: date):\n        self.desk, self.view, self.today = desk, view, today\n\n    def start(self) -> None:\n        self._refresh()", "note": "The presenter holds the model and the view, and the session's date, like the controller did."},
 {"code": "\n    def on_lend(self, code: str, member: str) -> None:\n        try:\n            loan = self.desk.lend(code, member, self.today)\n        except ValueError as err:\n            self.view.show_message(str(err), alarm=True)\n            return\n        self.view.show_message(f\"{code} lent to {member}, due {loan.due:%d/%m}\")\n        self._refresh()", "note": "The view calls this when somebody asks to lend. The presenter calls the model and then decides every word the person sees, including the date in day/month form."},
 {"code": "\n    def on_return(self, code: str) -> None:\n        try:\n            fine = self.desk.give_back(code, self.today)\n        except ValueError as err:\n            self.view.show_message(str(err), alarm=True)\n            return\n        if fine:\n            self.view.show_message(f\"{code} is back. Fine: {money(fine)}\", alarm=True)\n        else:\n            self.view.show_message(f\"{code} is back, on time\")\n        self._refresh()", "note": "Whether a return is an alarm is decided here. The view only learns that it should look alarming; how it does that is the one thing left to it."},
 {"code": "\n    def _refresh(self) -> None:\n        lines = [f\"{c}  on the shelf\" for c in sorted(self.desk.on_shelf)]\n        lines += [f\"{l.code}  {l.member}, due {l.due:%d/%m}\" for l in self.desk.loans.values()]\n        self.view.show_shelf(sorted(lines))", "note": "The presenter builds the shelf as finished lines and pushes them. The view does not sort, count or format anything."},
 {"code": "\n\nclass ConsoleView:\n    def show_shelf(self, lines: list[str]) -> None:\n        for line in lines:\n            print(\"   \", line)\n\n    def show_message(self, text: str, alarm: bool = False) -> None:\n        print(\"!!\" if alarm else \"--\", text)", "note": "The real view is so thin there is nothing in it to get wrong: it puts strings on the screen and marks alarms with `!!`. A window or a web page would implement the same two methods."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\n    presenter = DeskPresenter(desk, ConsoleView(), date(2026, 3, 2))\n    presenter.start()\n    presenter.on_lend(\"B2\", \"bia\")\n    presenter.today = date(2026, 3, 20)\n    presenter.on_return(\"B2\")", "note": "Here the main block plays the person at the desk, calling the presenter's event methods directly."}
]}
```

```
ana@laptop:~/patterns/presentation$ python3 mvp.py
    B1  on the shelf
    B2  on the shelf
    B3  on the shelf
-- B2 lent to bia, due 16/03
    B1  on the shelf
    B2  bia, due 16/03
    B3  on the shelf
!! B2 is back. Fine: R$ 2,00
    B1  on the shelf
    B2  on the shelf
    B3  on the shelf
```

Bia borrows B2 on 2 March, due on the 16th, and brings it back on the 20th: four days late, 200
cents, which the presenter turns into `R$ 2,00` and flags as an alarm. Every one of those decisions,
the `16/03`, the comma before the centavos, the `!!`, was made by `DeskPresenter`, and `ConsoleView`
made none of them.

## The test that needs no screen

That is the payoff. The presenter only knows the view through two methods, so a test can give it
any object with those two methods. This one writes down what it was asked to show:

```python
# test_presenter.py
import unittest
from datetime import date
from desk_model import Desk
from mvp import DeskPresenter


class FakeView:
    def __init__(self):
        self.shelf: list[str] = []
        self.messages: list[tuple[str, bool]] = []

    def show_shelf(self, lines):
        self.shelf = lines

    def show_message(self, text, alarm=False):
        self.messages.append((text, alarm))


class PresenterTest(unittest.TestCase):
    def setUp(self):
        self.view = FakeView()
        self.desk = Desk(["B1", "B2", "B3"], limit=2)
        self.presenter = DeskPresenter(self.desk, self.view, date(2026, 3, 2))

    def test_a_late_return_shows_the_fine_in_reais(self):
        self.presenter.on_lend("B1", "bia")
        self.presenter.today = date(2026, 3, 19)
        self.presenter.on_return("B1")
        self.assertEqual(self.view.messages[-1], ("B1 is back. Fine: R$ 1,50", True))

    def test_a_refusal_raises_the_alarm_and_leaves_the_shelf_alone(self):
        self.presenter.on_lend("B1", "bia")
        self.presenter.on_lend("B2", "bia")
        before = self.view.shelf
        self.presenter.on_lend("B3", "bia")
        self.assertEqual(self.view.messages[-1], ("bia already has 2 loans", True))
        self.assertIs(self.view.shelf, before)


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/presentation$ python3 -m unittest -v test_presenter.py
test_a_late_return_shows_the_fine_in_reais (test_presenter.PresenterTest.test_a_late_return_shows_the_fine_in_reais) ... ok
test_a_refusal_raises_the_alarm_and_leaves_the_shelf_alone (test_presenter.PresenterTest.test_a_refusal_raises_the_alarm_and_leaves_the_shelf_alone) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

The time on the `Ran 2 tests` line changes from run to run; the rest does not. The first test checks
a fine of three days, 150 cents, as it will appear on screen, `R$ 1,50`, and that it is an alarm.
The second checks that a refusal raises the alarm and leaves the shelf exactly as it was:
`assertIs` asserts it is the very same list object, so the presenter did not even redraw it.

**`FakeView` is a test double of the kind `testing-cicd` lesson 2 calls a spy**: it records the calls
so the test can assert on them afterwards. Compare what testing the same behaviour would take in
`mvc.py`, where the shelf line is formatted inside `ShelfView.render` and printed: capturing
standard output and matching text. In MVP, the only code a test cannot reach is `ConsoleView`, and
there is nothing in it but `print`.

## What it costs

**The view interface grows a method for every thing the screen can show.** Two methods are easy.
A real form has dozens of fields, each with a value, an enabled state and an error message, and the
protocol becomes `show_member_name`, `enable_lend_button`, `show_code_error` and the rest, each
implemented once in the real view and once in the fake. That boilerplate is the main complaint about
MVP, and it is what MVVM, the next section, removes with data binding.

There is a second, milder variant Fowler named *supervising controller*, where the view may bind
simple fields to the model itself and the presenter handles only the complicated logic. It trades
some testability for less code. The passive form here is the one that shows the idea most clearly.

## In your language

MVP has no built-in support anywhere, which is part of its appeal: it is three ordinary classes and
an interface. In **Java** it was the standard way to write Android screens before Google shipped
`ViewModel` in 2017, and GWT applications used it too; the view interface is a Java `interface`
that an `Activity` implements. In **TypeScript** the view is an `interface` and a component
implements it. In **Go**, which rarely draws screens, the same shape appears in terminal programs:
a presenter writing to an `io.Writer` through a small interface is MVP without the name.
