---
title: Setters, methods and plain functions
version: 1
---

**A dependency can also arrive after construction, with each call, or as a function argument, and
each of those has a case where it beats the constructor.** The common mistake is treating them as
equal alternatives and picking by taste. They are not equal: each moves the moment the dependency
arrives, and with it the moment a missing one is noticed.

The program below uses `overdue.py` from the previous section for `Loan` and `PrintNotifier`, so
keep it in the same directory.

```schooling-example
{"language": "python", "file": "forms.py", "parts": [
 {"code": "# forms.py\nfrom datetime import date\nfrom functools import partial\n\nfrom overdue import Loan, PrintNotifier", "note": "Only the loan and the printing notifier come from the previous file. Each form below is a few lines on its own."},
 {"code": "\n\nclass Reminder:\n    notifier = None  # set after construction\n\n    def remind(self, loan: Loan) -> None:\n        self.notifier.send(loan.member, f\"'{loan.title}' is due on {loan.due}\")", "note": "This is setter injection: the object is built empty and given its notifier afterwards, by assigning an attribute. Between the two steps it exists and is broken."},
 {"code": "\n\nclass Receipt:\n    def issue(self, loan: Loan, notifier) -> None:\n        notifier.send(loan.member, f\"you borrowed '{loan.title}' until {loan.due}\")", "note": "This is method injection. The receipt does not keep a notifier at all; each call says which one to use. The desk can print one receipt and e-mail the next."},
 {"code": "\n\ndef fine_for(loan: Loan, today: date, daily: int = 50) -> int:\n    return max((today - loan.due).days, 0) * daily", "note": "And this is a function parameter. In Python the smallest injection is an argument. The day is passed in, so the function has no clock to replace."},
 {"code": "\n\nfine_on_the_20th = partial(fine_for, today=date(2026, 3, 20))", "note": "`partial` fixes some arguments in advance and returns a new function. It is the function-shaped version of a constructor that stores its collaborators."},
 {"code": "\n\nif __name__ == \"__main__\":\n    loan = Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16))\n    try:\n        Reminder().remind(loan)\n    except AttributeError as err:\n        print(\"forgot the setter:\", err)\n    reminder = Reminder()\n    reminder.notifier = PrintNotifier()\n    reminder.remind(loan)\n    Receipt().issue(loan, PrintNotifier())\n    print(\"fine:\", fine_for(loan, date(2026, 3, 20)))\n    print(\"fine:\", fine_on_the_20th(loan))", "note": "The first call shows what setter injection costs when somebody forgets the second step: the error arrives at the first use, far from the line that should have set it."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 forms.py
forgot the setter: 'NoneType' object has no attribute 'send'
to Bia: 'Dom Casmurro' is due on 2026-03-16
to Bia: you borrowed 'Dom Casmurro' until 2026-03-16
fine: 200
fine: 200
```

The first line is the whole case against setters. `Reminder()` succeeded, and the object looked
fine until it was used. Python's message names `NoneType` and `send`, and says nothing about
`Reminder` or the assignment that never happened.

## When each one fits

| form | the dependency arrives | a missing one is noticed | fits when |
|---|---|---|---|
| constructor | once, when the object is built | at construction | the object cannot work without it: the default |
| setter | any time after construction | at first use | it is optional and has a sensible default, or a framework builds the object for you |
| method | with each call | at that call | it changes from call to call, like the channel of one receipt |
| function parameter | with each call, or fixed by `partial` | at that call | the code is a function rather than an object |

**Prefer the form that makes a missing dependency fail earliest.** That order is the table read from
top to bottom, with the function parameter beside the constructor rather than below the setter:
Python checks arguments the moment a function is called.

Setter injection has a respectable use. A setting with a default, say a logger that writes nowhere
until somebody sets one, is a setter that cannot be forgotten in any way that matters. Some
frameworks also build objects themselves and can only fill them in afterwards; older Java code
written for JavaBeans is full of setters for that reason. In code you construct yourself, a setter
for something the object cannot do without is a constructor argument that lost its guarantee.

## Functions are already injectable

Students coming from Java sometimes build a class with one method and a constructor, just to
inject a clock into it. In Python, Go, JavaScript and TypeScript a function is a value, so a
function that takes `today` as an argument has already received its dependency. **A function
argument is dependency injection with no ceremony at all**, and `partial`, a closure, or an arrow
function in TypeScript does what a constructor does when the same value is passed every time.

The class earns its place when several functions share the same collaborators: `OverdueNotices`
would pass the store, the notifier and the clock to every helper it had. That is when holding them
in fields is less noise than passing them around, and lesson 15 comes back to the same choice from
the functional side.
