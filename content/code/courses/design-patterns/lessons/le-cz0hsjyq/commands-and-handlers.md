---
title: Commands, handlers and the events they publish
version: 1
---

**On the write side, every change arrives as a command, an object naming one thing somebody wants
done, and one handler decides whether to do it.** The handler checks the rules against the write
model, makes the change or refuses, and on success publishes an event saying what happened. Three
kinds of object, and the grammar tells them apart: a command is imperative, `LendCopy`; an event is
past tense, `CopyLent`; a handler is a verb on the model.

The belief to drop is that commands are a way of calling methods with more ceremony. A command
is data. It can be logged, queued, retried, checked for permission or sent across a network before
anybody handles it, which a method call cannot. And an event is not a command in disguise: a
command can be refused, while an event reports a fact that is already true.

```schooling-example
{"language": "python", "file": "commands.py", "parts": [
 {"code": "# commands.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\n\n@dataclass(frozen=True)\nclass LendCopy:\n    copy_id: str\n    member: str\n    on: date\n\n\n@dataclass(frozen=True)\nclass ReturnCopy:\n    copy_id: str\n    on: date\n\n\n@dataclass(frozen=True)\nclass Reserve:\n    title_id: str\n    member: str", "note": "A command is a request in the imperative, carried as data: lend this copy to this member on this day. Frozen, because a request that changes on its way to the handler is a different request."},
 {"code": "\n\n@dataclass(frozen=True)\nclass CopyLent:\n    copy_id: str\n    title_id: str\n    member: str\n    due: date\n    was_reserved: bool\n\n\n@dataclass(frozen=True)\nclass CopyReturned:\n    copy_id: str\n    title_id: str\n    member: str\n    fine: int\n\n\n@dataclass(frozen=True)\nclass TitleReserved:\n    title_id: str\n    member: str", "note": "Events are what happened, in the past tense, with everything a reader will need: `CopyLent` carries the title and whether the loan used up a reservation, so a screen never has to ask the write model."},
 {"code": "\n\nclass Lending:\n    LIMIT = 5\n    DAILY_FINE = 50  # cents\n\n    def __init__(self, copies: dict[str, str]):\n        self.title_of = dict(copies)\n        self.holder: dict[str, tuple[str, date]] = {}\n        self.waiting: dict[str, list[str]] = {}\n        self.listeners = []", "note": "The write model. It holds what the rules check and nothing else: which title each copy belongs to, who holds each copy and until when, and the queue per title. There is no name and no author anywhere in it."},
 {"code": "\n    def _publish(self, event) -> None:\n        for listener in self.listeners:\n            listener(event)", "note": "After a change, the model tells whoever listens what happened. It does not know who they are; lesson 7's desk did the same with `subscribe`."},
 {"code": "\n    def lend(self, cmd: LendCopy) -> None:\n        title_id = self.title_of[cmd.copy_id]\n        queue = self.waiting.get(title_id, [])\n        if cmd.copy_id in self.holder:\n            raise ValueError(f\"{cmd.copy_id} is already out\")\n        if queue and queue[0] != cmd.member:\n            raise ValueError(f\"{title_id} is reserved for {queue[0]}\")\n        if sum(1 for m, _ in self.holder.values() if m == cmd.member) >= self.LIMIT:\n            raise ValueError(f\"{cmd.member} is at the limit\")\n        was_reserved = bool(queue)\n        if was_reserved:\n            queue.pop(0)\n        due = cmd.on + timedelta(days=14)\n        self.holder[cmd.copy_id] = (cmd.member, due)\n        self._publish(CopyLent(cmd.copy_id, title_id, cmd.member, due, was_reserved))", "note": "The handler for `LendCopy`: every rule, then the change, then the event. A refusal raises before anything changes, so a refused command publishes nothing."},
 {"code": "\n    def give_back(self, cmd: ReturnCopy) -> None:\n        if cmd.copy_id not in self.holder:\n            raise ValueError(f\"{cmd.copy_id} is not out\")\n        member, due = self.holder.pop(cmd.copy_id)\n        fine = max((cmd.on - due).days, 0) * self.DAILY_FINE\n        self._publish(CopyReturned(cmd.copy_id, self.title_of[cmd.copy_id], member, fine))", "note": "The fine is computed here, because it depends on the due date only the write side holds, and travels in the event so that no reader has to compute it again."},
 {"code": "\n    def reserve(self, cmd: Reserve) -> None:\n        queue = self.waiting.setdefault(cmd.title_id, [])\n        if cmd.member in queue:\n            raise ValueError(f\"{cmd.member} is already waiting for {cmd.title_id}\")\n        queue.append(cmd.member)\n        self._publish(TitleReserved(cmd.title_id, cmd.member))", "note": "Reserving twice is refused, which is a rule the strained class never had room to state."},
 {"code": "\n\nHANDLERS = {LendCopy: Lending.lend, ReturnCopy: Lending.give_back, Reserve: Lending.reserve}\n\n\ndef handle(model: Lending, command) -> None:\n    HANDLERS[type(command)](model, command)", "note": "Dispatch by the command's type. `handle` returns `None`: a command answers nothing, and anybody who wants to know the result asks a read model."},
 {"code": "\n\nif __name__ == \"__main__\":\n    lending = Lending({\"C1\": \"T1\", \"C2\": \"T1\", \"C3\": \"T2\", \"C4\": \"T3\"})\n    lending.listeners.append(lambda e: print(type(e).__name__, *(f\"{k}={v}\" for k, v in vars(e).items())))\n    day = date(2026, 3, 2)\n    for command in [LendCopy(\"C3\", \"caio\", day), Reserve(\"T2\", \"bia\"),\n                    ReturnCopy(\"C3\", date(2026, 3, 19)), LendCopy(\"C3\", \"dani\", date(2026, 3, 19)),\n                    LendCopy(\"C3\", \"bia\", date(2026, 3, 19))]:\n        try:\n            handle(lending, command)\n        except ValueError as err:\n            print(\"refused:\", err)", "note": "The listener here just prints each event, one line per event with its fields."}
]}
```

The second lending of C3 is the interesting one. Caio returns it on 19 March, three days late, so
the fine is 150 cents; Dani then asks for it and is refused because Bia reserved the title first;
Bia gets it, and her event says `was_reserved=True`:

```
ana@laptop:~/patterns/cqrs$ python3 commands.py
CopyLent copy_id=C3 title_id=T2 member=caio due=2026-03-16 was_reserved=False
TitleReserved title_id=T2 member=bia
CopyReturned copy_id=C3 title_id=T2 member=caio fine=150
refused: T2 is reserved for bia
CopyLent copy_id=C3 title_id=T2 member=bia due=2026-04-02 was_reserved=True
```

The refusal printed no event. **A refused command leaves no trace on the write model and tells no
listener anything**, because every rule is checked before the first assignment. That ordering is
the handler's main duty, and it is the same ordering lesson 1's `Loan.give_back` followed.

## Why the write model got smaller

Compare `Lending` with the strained `Library`. The names and authors are gone, and so are both
query methods. What is left is the three structures the rules read and the three handlers that
change them. When the committee adds a rule, say a member with an unpaid fine cannot borrow, the
change lands in one handler and its tests, and no screen's code is anywhere near it.

**Events are designed for their readers.** `CopyLent` carries `title_id` although the copy implies
it, and `was_reserved` although a reader could in principle work it out. A read model that had to
call back into `Lending` to understand an event would rebuild the coupling the split removed. The
next section shows why `was_reserved` had to be there: without it, the queue count on the screen
could only ever go up.

## Handlers in other shapes

The dispatch table `HANDLERS` maps a command's type to a function, which is the whole of what a
*command bus* in a framework does, plus middleware for logging, permissions and transactions around
each call. In Java that is often an interface `CommandHandler<C>` with one class per command,
registered in a Spring context; in TypeScript a discriminated union of command types and a `switch`
on the `type` field; in Go a type switch, `switch c := cmd.(type)`. Python's `match` statement, which
the next section uses on events, would serve here as well.

A handler that returns nothing makes some people uneasy: how does the screen show "B1 is due on the
16th"? Two honest answers. The screen asks a read model afterwards, which is the next two sections.
Or the handler returns an acknowledgement, an id or a due date, which bends command-query separation
in the way the previous section allowed. What it should not return is the screen's next view, for
the reason that section gave.
