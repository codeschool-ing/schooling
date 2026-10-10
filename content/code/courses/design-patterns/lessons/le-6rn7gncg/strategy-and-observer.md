---
title: Strategy and observer: behaviour you can swap, events you can follow
version: 1
---

**Strategy puts one varying decision behind an interface so the object that needs it can be handed
a different one; observer lets an object announce that something happened to any number of
listeners it knows nothing about.** They are the two behavioural patterns most likely to be in the
code you work on today, often without their names.

## Strategy: one decision, several ways to make it

A popular book has a waiting list. Who gets it next? First come, first served is the obvious rule.
The library committee wants to try giving priority to members who hold the fewest loans. Next
term it may be something else. The waiting list itself should not change each time the committee
does.

```schooling-example
{"language": "python", "file": "strategy.py", "parts": [
 {"code": "# strategy.py\nfrom dataclasses import dataclass\nfrom datetime import date\nfrom typing import Protocol\n\n\n@dataclass(frozen=True)\nclass Request:\n    member: str\n    placed: date\n    loans_held: int", "note": "A request records when it was placed and how many loans the member holds, which is everything either rule needs."},
 {"code": "\n\nclass Ordering(Protocol):\n    def order(self, requests: list[Request]) -> list[Request]: ...\n\n\nclass FirstCome:\n    def order(self, requests: list[Request]) -> list[Request]:\n        return sorted(requests, key=lambda r: r.placed)\n\n\nclass FewestLoansFirst:\n    def order(self, requests: list[Request]) -> list[Request]:\n        return sorted(requests, key=lambda r: (r.loans_held, r.placed))", "note": "The strategy interface and two strategies. Each is the whole of one rule, and each can be tested on a list of requests without a waiting list in sight."},
 {"code": "\n\nclass WaitingList:\n    def __init__(self, title: str, ordering: Ordering):\n        self.title, self.ordering = title, ordering\n        self._requests: list[Request] = []\n\n    def add(self, request: Request) -> None:\n        self._requests.append(request)\n\n    def queue(self) -> list[str]:\n        return [r.member for r in self.ordering.order(self._requests)]", "note": "The context, in the book's word. It keeps the requests and delegates the one decision it does not own. `ordering` is a public field, so the rule can change while the list lives."},
 {"code": "\n\nif __name__ == \"__main__\":\n    waiting = WaitingList(\"Torto Arado\", FirstCome())\n    waiting.add(Request(\"Bia\", date(2026, 5, 1), loans_held=4))\n    waiting.add(Request(\"Caio\", date(2026, 5, 2), loans_held=0))\n    waiting.add(Request(\"Duda\", date(2026, 5, 3), loans_held=1))\n    print(\"first come:  \", waiting.queue())\n    waiting.ordering = FewestLoansFirst()\n    print(\"fewest loans:\", waiting.queue())", "note": "The same three requests, ordered by each rule in turn."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 strategy.py
first come:   ['Bia', 'Caio', 'Duda']
fewest loans: ['Caio', 'Duda', 'Bia']
```

Bia asked first and holds four loans, so she leads one queue and trails the other. The committee's
next idea is a new class with one method, and `WaitingList` stays as it is: the open/closed
principle of lesson 3, met as a pattern. Lesson 1's channels were already strategies for
delivering a notice, before this lesson gave them the name.

**A strategy with one method is a function wearing a class.** In Python `sorted(requests, key=...)`
already takes the rule as an argument, and `FirstCome` could be `lambda rs: sorted(rs, key=...)`.
The class pays off when the strategy holds settings or has more than one method; the last reading
section of this lesson takes the function route further.

## Observer: announcing without knowing who listens

When a book comes back, several things should happen: the member at the head of its waiting list is
told, the count of returns for the day goes up, and later perhaps a recommendation is updated. The
returns desk should not grow a line for each of them.

```schooling-example
{"language": "python", "file": "observer.py", "parts": [
 {"code": "# observer.py\nfrom typing import Protocol\n\n\nclass ReturnListener(Protocol):\n    def returned(self, title: str, member: str) -> None: ...", "note": "The listener interface. Anything with a `returned` method can be told about a return."},
 {"code": "\n\nclass ReturnsDesk:\n    def __init__(self):\n        self._listeners: list[ReturnListener] = []\n\n    def subscribe(self, listener: ReturnListener) -> None:\n        self._listeners.append(listener)\n\n    def unsubscribe(self, listener: ReturnListener) -> None:\n        self._listeners.remove(listener)\n\n    def give_back(self, title: str, member: str) -> None:\n        print(f\"desk: {member} returned {title}\")\n        for listener in list(self._listeners):\n            listener.returned(title, member)", "note": "The subject. It keeps a list of listeners and calls each one after a return. It loops over a copy, so a listener can unsubscribe while being told."},
 {"code": "\n\nclass ReservationAlert:\n    def __init__(self, waiting: dict[str, str]):\n        self._waiting = waiting\n\n    def returned(self, title: str, member: str) -> None:\n        if title in self._waiting:\n            print(f\"  alert: tell {self._waiting.pop(title)} that {title} is in\")\n\n\nclass ReturnCount:\n    def __init__(self):\n        self.today = 0\n\n    def returned(self, title: str, member: str) -> None:\n        self.today += 1\n        print(f\"  count: {self.today} returned today\")", "note": "Two listeners that know the desk's interface and not each other. Neither is mentioned anywhere in `ReturnsDesk`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = ReturnsDesk()\n    count = ReturnCount()\n    desk.subscribe(ReservationAlert({\"Vidas Secas\": \"Caio\"}))\n    desk.subscribe(count)\n    desk.give_back(\"Dom Casmurro\", \"Bia\")\n    desk.give_back(\"Vidas Secas\", \"Duda\")\n    desk.unsubscribe(count)\n    desk.give_back(\"Quincas Borba\", \"Bia\")", "note": "Three returns. The count unsubscribes before the third, and the desk does not notice the difference."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 observer.py
desk: Bia returned Dom Casmurro
  count: 1 returned today
desk: Duda returned Vidas Secas
  alert: tell Caio that Vidas Secas is in
  count: 2 returned today
desk: Bia returned Quincas Borba
```

## What observer costs

The desk no longer knows what happens after a return, which is the point, and also the price.
**Reading `give_back` no longer tells you what a return does**: the answer is spread across
whoever subscribed, and it changes at run time. Three failures follow from that.

A listener that raises stops the loop, and the listeners after it are never told. Production code
catches and logs per listener, and then has to decide whether a failed alert should fail the
return. A listener that is never unsubscribed keeps its object alive for as long as the subject
lives, the "lapsed listener" leak. And the order of notification is the order of subscription,
which is easy to start depending on without anybody writing it down.

Observer is the root of a large family. Event handlers in a browser, signals in Django, and the
domain events of lesson 12 are all observer. Lesson 16 turns it into a stream with operators, and
lesson 18 shows what happens when the list of listeners is changed by one thread while another is
walking it.
