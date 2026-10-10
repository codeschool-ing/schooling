---
title: Immutability helps: what cannot change needs no lock
version: 1
---

**Every race in this lesson needed state that was shared and written. Take away the writing and
there is nothing to race on.** An object that cannot change after it is built can be read by any
number of threads at once, with no lock and no care, because every reader sees the same thing for
as long as the object exists. Lesson 15 made the case for immutability as a way to reason about
code; under threads it becomes a way to stay correct.

What changes instead is *which* object is current. An update builds a new value and swaps one
reference to point at it. A reader that picked up the old reference keeps a complete, consistent
old value; a reader that comes later gets the complete new one. Nobody can see half of each.

## A torn read, and a clean one

The library's fine rules have two numbers: cents per day and days of grace. Tonight they change
from 50 cents with no grace to 100 cents with two days' grace. A desk computes a fine while the
change is happening. The program does it twice, once with a mutable dictionary and once with a
frozen dataclass, and stops the reader at the worst moment on purpose.

```schooling-example
{"language": "python", "file": "rules.py", "parts": [
 {"code": "# rules.py\nimport dataclasses\nimport threading\nfrom dataclasses import dataclass\n\n\n@dataclass(frozen=True)\nclass FineRules:\n    daily_cents: int\n    grace_days: int\n\n\ndef fine(rules: FineRules, days_late: int) -> int:\n    return max(days_late - rules.grace_days, 0) * rules.daily_cents", "note": "`frozen=True` makes the dataclass refuse assignment after construction. The rules are a value, as in lesson 12."},
 {"code": "\nmutable = {\"daily_cents\": 50, \"grace_days\": 0}\ncurrent = FineRules(daily_cents=50, grace_days=0)\nhalfway = threading.Event()\nread_done = threading.Event()", "note": "Two places the rules live: a dictionary changed field by field, and a reference to a frozen object. The two events let the main thread read exactly halfway through an update."},
 {"code": "\ndef update_mutable() -> None:\n    mutable[\"daily_cents\"] = 100\n    halfway.set()\n    read_done.wait()\n    mutable[\"grace_days\"] = 2", "note": "Updating the dictionary takes two writes, and a reader can arrive between them."},
 {"code": "\ndef update_frozen() -> None:\n    global current\n    new = FineRules(daily_cents=100, grace_days=2)\n    halfway.set()\n    read_done.wait()\n    current = new", "note": "Updating the frozen rules builds the whole new value first, then changes one reference. The reader arrives at the same point: after the work, before the swap."},
 {"code": "\ndef show(label: str, rules: FineRules) -> None:\n    print(f\"{label:<8} {rules.daily_cents} cents a day, {rules.grace_days} days' grace,\"\n          f\" 3 days late costs {fine(rules, 3)}\")\n\n\ndef demo(label: str, update, snapshot) -> None:\n    halfway.clear()\n    read_done.clear()\n    writer = threading.Thread(target=update)\n    writer.start()\n    halfway.wait()\n    show(label, snapshot())\n    read_done.set()\n    writer.join()", "note": "`demo` starts the writer, reads when it is halfway, then lets it finish. `snapshot` says how each version reads its rules."},
 {"code": "\nif __name__ == \"__main__\":\n    print(\"old: 50 cents, no grace -> new: 100 cents, 2 days' grace\")\n    demo(\"mutable\", update_mutable, lambda: FineRules(**mutable))\n    demo(\"frozen\", update_frozen, lambda: current)\n    show(\"after\", current)\n    try:\n        current.daily_cents = 0\n    except dataclasses.FrozenInstanceError as err:\n        print(\"refused:\", err)", "note": "Both versions, the frozen rules once the swap is done, and an attempt to change a frozen object in place."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 rules.py
old: 50 cents, no grace -> new: 100 cents, 2 days' grace
mutable  100 cents a day, 0 days' grace, 3 days late costs 300
frozen   50 cents a day, 0 days' grace, 3 days late costs 150
after    100 cents a day, 2 days' grace, 3 days late costs 100
refused: cannot assign to field 'daily_cents'
```

Read the second line closely. The mutable reader saw the new price with the old grace, and charged
300 cents for three days late. Under the old rules that fine was 150; under the new ones, 100.
**The reader computed a fine from a rule set that nobody ever configured.** That is a torn read,
and a lock around both writes and the read would fix it, at the price of every reader taking the
lock.

The frozen reader saw the old rules, whole, and charged 150. A moment later the reference pointed
at the new rules, whole, and the fine was 100. No lock was taken anywhere. The last line is the
guarantee that makes it safe: nobody can change those fields after the object is built, including
by accident in some other module.

## The rule behind it, and its fine print

**Share what is immutable; confine what is mutable.** Confined means owned by exactly one thread,
which is the only one that ever touches it; other threads send it messages. That second half is
lesson 17's actor model, and `queue.Queue` is Python's ready-made way to pass ownership of a value
from one thread to another.

Two pieces of fine print. First, swapping the reference is safe in CPython because assigning a
global is a single step that no thread can see half-done. The same move in other languages needs a
word for it:

| language | how a new immutable value is published to other threads |
|---|---|
| Python | plain assignment of the reference |
| Java | a `volatile` field or an `AtomicReference`; a plain field may never be seen by another thread |
| Go | `atomic.Pointer[T]`, or a mutex; `go test -race` reports a plain write and read |
| TypeScript | not needed on one event loop; between workers, a message with a copy of the value |

Second, *frozen* is only as deep as its fields. A frozen dataclass holding a `list` stops you
replacing the list and lets anybody append to it. Use tuples and other frozen objects all the way
down, as lesson 15 did, or the lock you avoided comes back through the side door.

Immutability does not remove every race. A swap based on what you read, *read the rules, add a
day of grace, publish*, is read-modify-write again, and two threads doing it at once lose one
update exactly as `race.py` did. Writers still need to take turns, or a single owner. Readers,
which are usually the many, need nothing at all.
