---
title: "Domain events: what happened, said by the model"
version: 1
---

**A domain event is a record, made by the aggregate itself, that something the business cares
about has happened.** A member borrowing a copy is a `LoanStarted`. A late return is a
`FineCharged`. The aggregate records the event as part of the change; code outside reacts to it
afterwards, without the aggregate knowing who listens.

The wrong idea is that the aggregate should do the reactions itself. `borrow` sends the SMS
receipt, `give_back` e-mails the fine notice, and both bump the "popular this week" counter. Now the
member depends on an SMS gateway and an e-mail server, a test of the five-loan rule needs fakes for
both, and adding a reaction means editing the aggregate. **The member's job is to say what
happened; deciding what to do about it belongs elsewhere.** That is lesson 4's dependency rule
applied to time.

These are the same orange notes lesson 11 put on the wall, and the same kind of fact lesson 9
stored. The difference is where they come from: here the model raises them as it changes. Here is
`member.py` again, whole, with events added. Replace the earlier file with this one:

```schooling-example
{"language": "python", "file": "member.py", "parts": [
 {"code": "# member.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nfrom money import Money\n\nMAX_LOANS = 5\nFINE_LIMIT = Money(1000)\nDAILY_FINE = Money(50)\nLOAN_DAYS = {\"book\": 14, \"film\": 7}\n\n\nclass Refused(Exception):\n    pass\n\n\n@dataclass\nclass Loan:\n    copy_id: str\n    due: date", "note": "Everything down to `Loan` is as it was in the aggregates section."},
 {"code": "\n\n@dataclass(frozen=True)\nclass LoanStarted:\n    member_id: str\n    copy_id: str\n    due: date\n\n\n@dataclass(frozen=True)\nclass FineCharged:\n    member_id: str\n    copy_id: str\n    amount: Money", "note": "Two events, named in the past tense the way lesson 11 wrote them on the wall, and frozen, because a fact does not change after it happens. Each carries ids and values, never a `Member`."},
 {"code": "\n\nclass Member:\n    def __init__(self, member_id: str, name: str):\n        self.id = member_id\n        self.name = name\n        self._loans: list[Loan] = []\n        self.owed = Money(0)\n        self._events: list[object] = []\n\n    @property\n    def loans(self) -> tuple[Loan, ...]:\n        return tuple(self._loans)", "note": "`_events` is the new field: what has happened to this member since it was loaded."},
 {"code": "\n    def pull_events(self) -> list[object]:\n        events, self._events = self._events, []\n        return events", "note": "`pull_events` hands the list over and empties it, so the same event is never handed out twice."},
 {"code": "\n    def borrow(self, copy_id: str, kind: str, today: date) -> Loan:\n        if len(self._loans) >= MAX_LOANS:\n            raise Refused(f\"{self.name} already has {MAX_LOANS} loans\")\n        if self.owed.cents > FINE_LIMIT.cents:\n            raise Refused(f\"{self.name} owes {self.owed}, over the limit of {FINE_LIMIT}\")\n        loan = Loan(copy_id, today + timedelta(days=LOAN_DAYS[kind]))\n        self._loans.append(loan)\n        self._events.append(LoanStarted(self.id, copy_id, loan.due))\n        return loan", "note": "The event is recorded after the change has succeeded, on the line after it. A refused loan raises first and records nothing."},
 {"code": "\n    def give_back(self, copy_id: str, on: date) -> Money:\n        loan = next((l for l in self._loans if l.copy_id == copy_id), None)\n        if loan is None:\n            raise Refused(f\"{self.name} has no loan of {copy_id}\")\n        self._loans.remove(loan)\n        fine = DAILY_FINE.times(max((on - loan.due).days, 0))\n        self.owed = self.owed + fine\n        if fine.cents:\n            self._events.append(FineCharged(self.id, copy_id, fine))\n        return fine", "note": "A fine of zero is not an event; nothing happened that anybody needs to hear about."},
 {"code": "\n    def pay(self, amount: Money) -> None:\n        self.owed = self.owed - amount"}
]}
```

And the code that reacts. It loads a member through the repository from the last section, asks it
to do something, saves it and publishes what happened:

```schooling-example
{"language": "python", "file": "handlers.py", "parts": [
 {"code": "# handlers.py\nfrom datetime import date\n\nfrom member import FineCharged, LoanStarted, Member\nfrom repositories import InMemoryMembers\n\npopular: dict[str, int] = {}\n\n\ndef send_receipt(event: LoanStarted) -> None:\n    print(f\"  SMS to {event.member_id}: {event.copy_id} is due on {event.due}\")\n\n\ndef count_popular(event: LoanStarted) -> None:\n    popular[event.copy_id] = popular.get(event.copy_id, 0) + 1\n\n\ndef send_fine_notice(event: FineCharged) -> None:\n    print(f\"  e-mail to {event.member_id}: a fine of {event.amount} for {event.copy_id}\")", "note": "Handlers are plain functions, one per reaction. The member knows none of them."},
 {"code": "\n\nHANDLERS = {LoanStarted: [send_receipt, count_popular], FineCharged: [send_fine_notice]}\n\n\ndef publish(events: list[object]) -> None:\n    for event in events:\n        for handle in HANDLERS[type(event)]:\n            handle(event)", "note": "The wiring: which handlers hear which event. Adding a reaction is a line here, and `member.py` does not change."},
 {"code": "\n\ndef run(members: InMemoryMembers, member_id: str, action) -> None:\n    member = members.get(member_id)\n    action(member)\n    events = member.pull_events()\n    members.save(member)\n    publish(events)", "note": "The order matters. Events are pulled before saving and published after: the in-memory repository stores a deep copy, events included, and a member saved with its events would hand them out again on the next `get`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    members = InMemoryMembers()\n    members.save(Member(\"m-001\", \"Bia\"))\n    print(\"borrow:\")\n    run(members, \"m-001\", lambda m: m.borrow(\"C-0002\", \"film\", date(2026, 3, 2)))\n    print(\"give back late:\")\n    run(members, \"m-001\", lambda m: m.give_back(\"C-0002\", date(2026, 3, 12)))\n    print(\"popular:\", popular)"}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 handlers.py
borrow:
  SMS to m-001: C-0002 is due on 2026-03-09
give back late:
  e-mail to m-001: a fine of BRL 1.50 for C-0002
popular: {'C-0002': 1}
```

Borrowing the film produced one `LoanStarted`, and two handlers heard it: one sent the receipt,
the other counted the copy as popular. Giving it back on 12 March, three days late, produced a
`FineCharged` of `BRL 1.50`, and the fine notice went out. The counter ended at 1. The member
contains no SMS, no e-mail and no counter.

## Save first, then publish

The order in `run` matters, and the transcript shows what each part guards against. Publishing
before saving would send Bia a receipt for a loan that a failed save then lost. Publishing after
saving can fail too, which leaves a saved loan with no receipt; for a receipt that is acceptable,
and for a rule that another aggregate depends on it is not. That second case is where the *outbox*
comes in: the events are written in the same transaction as the aggregate, to a table, and a
separate job publishes them and marks them sent. It is lesson 10's unit of work holding one more
list.

## What goes in an event

| keep | leave out |
|---|---|
| a name in the past tense, from the ubiquitous language | a name like `MemberUpdated` that says nothing happened in particular |
| ids: the member's, the copy's | the `Member` object, which the handler could then change |
| the values the change produced: the due date, the amount | values a handler could look up for itself and that may change |
| immutability: `frozen=True` | anything a handler might be tempted to edit |

The events here are handled in the same process, right after the save. Lesson 9 kept events in a
store, rebuilt state from them and fed projections with them, the handlers that build lesson 8's
read models. A domain event is where all of that starts: the moment the model says *this happened*.
