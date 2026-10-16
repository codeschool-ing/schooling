---
title: "Ubiquitous language: one word, one meaning, everywhere"
version: 1
---

**A ubiquitous language is the set of words that the people who run the business and the people
who write the code both use, with the same meaning, in conversation, in documents and in the code
itself.** Evans gave it the name. The word *ubiquitous* is the demand. The words appear in the class names, the method names and
the error messages, and a glossary in a wiki that the code ignores does not count: a librarian
should be able to read a stack trace and recognise her own job in it.

The usual state of affairs is two languages and a translator. The business says *the hold has
lapsed*; the code says `r["st"] = 4`. Somebody on the team knows that status 4 means lapsed, and
every conversation goes through that person's head. Translation is where meaning leaks: the day
somebody adds status 5 for "cancelled by the member" and forgets that the report counts 4 and 5
together as "not collected", the report is wrong and nobody can see it from the code.

## Writing the glossary down

Start with a table, made with the librarians, of the words they actually use. Not the words the
developers would like them to use. Four rows from the library's:

| word | what the librarians mean | what it is not |
|---|---|---|
| hold | a member's place in the queue for a title | a loan; nothing has been handed over |
| shelve | put a returned copy on the hold shelf for the member at the front of the queue | put it back in the stacks |
| pickup deadline | the last day the member can collect: 7 days after shelving | the loan's due date |
| lapse | what a hold does when the deadline passes uncollected; the copy goes to the next member | a cancellation, which the member asks for |

The third column is where the value is. Every row there is a confusion that somebody on the team
had, and that the code would otherwise have encoded.

## The words in the code

Here is the code that used to say `r["st"] = 4`, written in the glossary's words. Make the lesson's
directory first:

```sh
mkdir -p ~/patterns/ddd-strategic
cd ~/patterns/ddd-strategic
```

```schooling-example
{"language": "python", "file": "holds.py", "parts": [
 {"code": "# holds.py\nfrom datetime import date, timedelta\n\nPICKUP_DAYS = 7", "note": "`PICKUP_DAYS` is the librarians' \"a week on the hold shelf\", with the word they use for it."},
 {"code": "\n\nclass Hold:\n    def __init__(self, member: str, title: str, placed_on: date):\n        self.member = member\n        self.title = title\n        self.placed_on = placed_on\n        self.shelved_on: date | None = None\n        self.collected = False", "note": "A hold is placed by a member for a title. It has not been shelved and has not been collected; those are the two things that will happen to it."},
 {"code": "\n    def shelve(self, on: date) -> None:\n        self.shelved_on = on\n\n    def pickup_deadline(self) -> date:\n        return self.shelved_on + timedelta(days=PICKUP_DAYS)\n\n    def has_lapsed(self, today: date) -> bool:\n        return (self.shelved_on is not None and not self.collected\n                and today > self.pickup_deadline())", "note": "Each method is a sentence from the desk: the copy is *shelved*, the member must collect it by the *pickup deadline*, and a hold not collected by then has *lapsed*."},
 {"code": "\n    def collect(self, on: date) -> None:\n        if self.shelved_on is None:\n            raise ValueError(f\"{self.title!r} is not on the hold shelf yet\")\n        if self.has_lapsed(on):\n            raise ValueError(f\"the hold on {self.title!r} was not collected by {self.pickup_deadline()}\")\n        self.collected = True", "note": "The two refusals are the two things a librarian would say at the desk, and the messages say them in those words."},
 {"code": "\n\nif __name__ == \"__main__\":\n    hold = Hold(\"Bia\", \"Vidas Secas\", placed_on=date(2026, 5, 4))\n    try:\n        hold.collect(date(2026, 5, 5))\n    except ValueError as err:\n        print(\"refused:\", err)\n    hold.shelve(date(2026, 5, 11))\n    print(\"collect by:\", hold.pickup_deadline())\n    print(\"lapsed on 18 May?\", hold.has_lapsed(date(2026, 5, 18)))\n    print(\"lapsed on 19 May?\", hold.has_lapsed(date(2026, 5, 19)))\n    try:\n        hold.collect(date(2026, 5, 19))\n    except ValueError as err:\n        print(\"refused:\", err)", "note": "Bia tries to collect too early, the copy is shelved on 11 May, and she comes on the 19th, one day late."}
]}
```

```
ana@laptop:~/patterns/ddd-strategic$ python3 holds.py
refused: 'Vidas Secas' is not on the hold shelf yet
collect by: 2026-05-18
lapsed on 18 May? False
lapsed on 19 May? True
refused: the hold on 'Vidas Secas' was not collected by 2026-05-18
```

The hold cannot be collected before it is shelved, and the message says so in the desk's words.
Shelved on 11 May, it must be collected by the 18th; on the 18th it has not lapsed, on the 19th it
has, and collecting then is refused with a sentence a librarian would say. **Nothing in this file
needs translating for the person who decides the rules**, and that is the test of a ubiquitous
language: read the method names aloud to a librarian and see whether she corrects you.

## When the language changes, the code changes

The language is not fixed at the start. Six months in, the librarians decide that a lapsed hold
gets one more day before the copy moves on, and in the meeting
somebody calls that a *second chance*. The ubiquitous-language move is to rename and reshape the
code in the same week: a `second_chance` method, a test named after it, and the word in the
glossary. The alternative, a flag called `retry_lapsed` that only developers understand, is how the
two languages drift apart again, one convenient name at a time.

Two warnings from practice. A ubiquitous language is not one language for the whole organisation:
the next two sections find the same word meaning different things in different parts of the
library, and that is normal. And English code with Portuguese business words is fine: the classes
here could be called `Reserva` and `prateleira_de_reservas` if that is what the team and the
librarians say. What matters is one word per meaning, used by both sides.
