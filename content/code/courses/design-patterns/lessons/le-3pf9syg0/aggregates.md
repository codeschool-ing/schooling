---
title: "Aggregates: one door to a cluster of objects"
version: 1
---

**An aggregate is a cluster of objects that must stay consistent together, with one of them, the
root, as the only door: everything outside talks to the root, and the root keeps the rules.** A
member and her loans are an aggregate. The rule "at most five loans" is about the loans together,
so no single loan can keep it. The member can, provided every new loan has to come through her.

The wrong idea is that the rule can live in whichever service adds loans. The lending desk checks
the count before adding a loan; then the online renewal, written later, adds a loan without
checking; then a migration script imports loans straight into the list. Each path is reasonable
and one of them breaks the rule. **An invariant kept by every caller is an invariant kept by
none.** Put the rule where the list is, and make the list unreachable except through it.

Here is the member as an aggregate, using `Money` from the last section:

```schooling-example
{"language": "python", "file": "member.py", "parts": [
 {"code": "# member.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nfrom money import Money\n\nMAX_LOANS = 5\nFINE_LIMIT = Money(1000)\nDAILY_FINE = Money(50)\nLOAN_DAYS = {\"book\": 14, \"film\": 7}\n\n\nclass Refused(Exception):\n    pass", "note": "The rules of lending, as constants beside the class that keeps them. `Money` comes from the last section."},
 {"code": "\n\n@dataclass\nclass Loan:\n    copy_id: str\n    due: date", "note": "A `Loan` has no id of its own: inside the member it is told apart by the copy it is for. Nothing outside the aggregate holds a `Loan`."},
 {"code": "\n\nclass Member:\n    def __init__(self, member_id: str, name: str):\n        self.id = member_id\n        self.name = name\n        self._loans: list[Loan] = []\n        self.owed = Money(0)\n\n    @property\n    def loans(self) -> tuple[Loan, ...]:\n        return tuple(self._loans)", "note": "The root. Its list of loans is private, and `loans` hands out a tuple, so nobody can append to the list without going through `borrow`."},
 {"code": "\n    def borrow(self, copy_id: str, kind: str, today: date) -> Loan:\n        if len(self._loans) >= MAX_LOANS:\n            raise Refused(f\"{self.name} already has {MAX_LOANS} loans\")\n        if self.owed.cents > FINE_LIMIT.cents:\n            raise Refused(f\"{self.name} owes {self.owed}, over the limit of {FINE_LIMIT}\")\n        loan = Loan(copy_id, today + timedelta(days=LOAN_DAYS[kind]))\n        self._loans.append(loan)\n        return loan", "note": "Both invariants are checked here, before anything changes: at most five loans, and nothing new while more than 1000 cents are owed."},
 {"code": "\n    def give_back(self, copy_id: str, on: date) -> Money:\n        loan = next((l for l in self._loans if l.copy_id == copy_id), None)\n        if loan is None:\n            raise Refused(f\"{self.name} has no loan of {copy_id}\")\n        self._loans.remove(loan)\n        fine = DAILY_FINE.times(max((on - loan.due).days, 0))\n        self.owed = self.owed + fine\n        return fine\n\n    def pay(self, amount: Money) -> None:\n        self.owed = self.owed - amount", "note": "Returning removes the loan and adds the fine in one method, so the two can never get out of step."},
 {"code": "\n\nif __name__ == \"__main__\":\n    bia = Member(\"m-001\", \"Bia\")\n    day = date(2026, 3, 2)\n    for n in range(1, 7):\n        try:\n            loan = bia.borrow(f\"C-{n:04d}\", \"film\" if n == 2 else \"book\", day)\n            print(\"lent\", loan.copy_id, \"due\", loan.due)\n        except Refused as err:\n            print(\"refused:\", err)\n    print(\"fine:\", bia.give_back(\"C-0002\", date(2026, 4, 1)))\n    try:\n        bia.borrow(\"C-0007\", \"book\", date(2026, 4, 1))\n    except Refused as err:\n        print(\"refused:\", err)\n    bia.pay(Money(1150))\n    print(\"lent\", bia.borrow(\"C-0007\", \"book\", date(2026, 4, 1)).copy_id, \"| loans:\", len(bia.loans))", "note": "Six books asked for, one a film; a late return; a refusal because of the fine; a payment; and the loan that now fits."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 member.py
lent C-0001 due 2026-03-16
lent C-0002 due 2026-03-09
lent C-0003 due 2026-03-16
lent C-0004 due 2026-03-16
lent C-0005 due 2026-03-16
refused: Bia already has 5 loans
fine: BRL 11.50
refused: Bia owes BRL 11.50, over the limit of BRL 10.00
lent C-0007 | loans: 5
```

Five loans go out, one of them a film due on 9 March rather than 16, and the sixth is refused. The
film comes back on 1 April, 23 days late, and the fine is `BRL 11.50`. With that owed, the next
loan is refused, because 1150 cents is over the limit of 1000. Bia pays, and the loan that was
refused now goes out, bringing her back to five.

## The rules of the root

Evans's rules for aggregates are short, and `member.py` keeps each one:

- outside code holds a reference to the root only. Nothing outside the file keeps a `Loan`;
  `loans` hands out a tuple, a snapshot that cannot be appended to;
- every change goes through a method of the root, and the method checks the invariants before it
  changes anything. `borrow` checks both limits before the `append`;
- an object inside the aggregate needs an identity only within it. A `Loan` is told apart by its
  `copy_id`, which is enough inside one member;
- the aggregate is loaded and saved whole. A repository for loans on their own would be a second
  door, and the rule would leak out through it. The repositories section shows the member saved as
  one piece.

Python's underscore on `_loans` is a convention, as lesson 1 said, and the tuple is the part that
does the work: code that writes `bia.loans.append(...)` fails at once, because a tuple has no
`append`. Java's `List.copyOf` or `Collections.unmodifiableList`, Go's returning a copy of the
slice, and TypeScript's `ReadonlyArray` are the same move.

## Factories, briefly

When making an aggregate takes more than a constructor should do, such as checking that a card
number is free or giving a new member a welcome loan allowance, the creation gets a home of its
own: a **factory**. In Python that is usually a function or a class method, `Member.join(...)`, that
does the checks and returns a valid root. The point is the same as the root's: nobody can obtain an
aggregate in a state that breaks its rules, not even at birth. Lesson 6's factory method is the
same pattern seen from the GoF side.

## How big?

Small. An aggregate is the unit of consistency, so everything inside it is locked, loaded and saved
together. A member who contained her loans, her holds, her payment history and every copy she ever
touched would be a correct model and a slow one, and two librarians editing different parts of her
would collide. The next section is about drawing that line, and about what to do with the rules
that cross it.
