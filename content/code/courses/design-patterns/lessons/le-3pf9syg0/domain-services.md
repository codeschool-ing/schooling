---
title: "Domain services: rules that belong to no single object"
version: 1
---

**A domain service is an operation of the domain that does not belong naturally to any entity or
value object, so it gets a class or a function of its own, named in the ubiquitous language.** It
holds rules, not data about one member or one copy, and it is as much a part of the model as
`Member` is.

The library closes for Carnaval. A book due on the Friday before comes back on the Thursday after,
and the librarians say the two days the library was shut should not count towards the fine: the
member could not have returned it. Where does that rule go? `Loan` knows its due date and nothing
about the calendar. `Member` could be given the calendar, but then every member carries the
library's holidays around. **When a rule needs knowledge that no single object should hold, the rule
gets its own home.**

The wrong idea runs the other way: that any logic outside an entity is a "service", and that a
model with a `LendingService` full of methods is a fine design. That is the *anaemic domain model*,
Martin Fowler's name for entities that are bags of fields while services do all the work. The
member's five-loan rule belongs in `Member`, as two sections back showed. A domain service is the
exception for the rules that genuinely have no owner.

```schooling-example
{"language": "python", "file": "closures.py", "parts": [
 {"code": "# closures.py\nfrom datetime import date, timedelta\n\nfrom money import Money\n\nDAILY_FINE = Money(50)\n\n\nclass FinePolicy:\n    def __init__(self, closed_days: set[date]):\n        self.closed_days = closed_days", "note": "The domain service is a class named in the domain's words, holding the one thing neither `Member` nor `Loan` has: the library's calendar of closed days."},
 {"code": "\n    def late_days(self, due: date, returned: date) -> int:\n        days = (returned - due).days\n        counted = [due + timedelta(days=n) for n in range(1, days + 1)]\n        return sum(1 for d in counted if d not in self.closed_days)\n\n    def fine_for(self, due: date, returned: date) -> Money:\n        return DAILY_FINE.times(self.late_days(due, returned))", "note": "Every day after the due date counts, unless the library was closed that day. It is pure: dates in, a number out, nothing stored."},
 {"code": "\n\nif __name__ == \"__main__\":\n    carnaval = {date(2026, 2, 16), date(2026, 2, 17)}\n    policy = FinePolicy(closed_days=carnaval)\n    due, back = date(2026, 2, 13), date(2026, 2, 19)\n    print(\"calendar days late:\", (back - due).days)\n    print(\"days the library was open:\", policy.late_days(due, back))\n    print(\"fine:\", policy.fine_for(due, back))\n    print(\"no closures:\", FinePolicy(set()).fine_for(due, back))", "note": "Carnaval 2026 fell on 16 and 17 February. A book due on Friday the 13th comes back on Thursday the 19th."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 closures.py
calendar days late: 6
days the library was open: 4
fine: BRL 2.00
no closures: BRL 3.00
```

The book was six calendar days late, and the library was open on four of them, so the fine is
`BRL 2.00` rather than the `BRL 3.00` the naive count gives. The policy takes the calendar once and
answers for any loan. `Member.give_back` would receive it as an argument and ask it for the fine,
instead of multiplying days by 50 cents itself, which is a one-line change to the method in the
domain-events section.

## Domain service or application service?

Two kinds of service live near the domain, and mixing them up is how domain rules end up scattered
across controllers:

| | domain service | application service |
|---|---|---|
| holds | a business rule | the steps of a use case |
| example | `FinePolicy.fine_for` | `lend_copy` from the repositories section: load, ask, save |
| speaks | the ubiquitous language | the language of the program: repositories, transactions, events |
| knows about storage | no | yes |
| testable with | plain values | the in-memory repository |

`handlers.run` and `lend_copy` are application services: they coordinate, and every decision in
them is delegated to an aggregate. `FinePolicy` decides something. A useful check is to read the
service's code to a librarian. If she recognises the rule, it is a domain service; if she hears
only "load, save, publish", it is the application layer.

## The tactical patterns, together

Entities give the members and copies identity, value objects give money its rules, aggregates draw
the boundary each rule is kept inside, repositories store one aggregate at a time, domain events
carry the change across boundaries, and domain services hold the few rules nobody owns. Lesson 11
decided where the lending context ends; this lesson filled it. Lesson 13 tests the same kind of code
as it is written, rule by rule.
