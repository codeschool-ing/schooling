---
title: Command and state: requests as objects, behaviour that changes with the situation
version: 1
---

**Command turns a request into an object, so it can be stored, queued, logged and undone; state
gives an object a different behaviour in each situation it can be in.** State does it by handing
each call to an object that stands for the current situation. Both replace something that is usually implicit, a method call or
a tangle of `if status == ...`, with something you can name and hold.

## Command: a request you can keep

A method call happens and is gone. If the desk wants to undo the last thing it did, it needs a
record of what that was and how to reverse it. Command makes each action an object with an
`execute` and an `undo`, and the desk keeps a list of them.

```schooling-example
{"language": "python", "file": "command.py", "parts": [
 {"code": "# command.py\nfrom typing import Protocol\n\n\nclass Command(Protocol):\n    def execute(self) -> None: ...\n    def undo(self) -> None: ...\n\n\nclass Shelf:\n    def __init__(self, titles: list[str]):\n        self.available = set(titles)\n        self.on_loan: dict[str, str] = {}\n\n    def report(self) -> str:\n        return f\"available {sorted(self.available)}, on loan {self.on_loan}\"", "note": "The command interface, and the shelf the commands act on. The shelf is plain data; it knows nothing about undo."},
 {"code": "\n\nclass Lend:\n    def __init__(self, shelf: Shelf, title: str, member: str):\n        self.shelf, self.title, self.member = shelf, title, member\n\n    def execute(self) -> None:\n        self.shelf.available.remove(self.title)\n        self.shelf.on_loan[self.title] = self.member\n\n    def undo(self) -> None:\n        del self.shelf.on_loan[self.title]\n        self.shelf.available.add(self.title)\n\n    def __str__(self) -> str:\n        return f\"lend {self.title} to {self.member}\"\n\n\nclass Return:\n    def __init__(self, shelf: Shelf, title: str):\n        self.shelf, self.title, self.member = shelf, title, \"\"\n\n    def execute(self) -> None:\n        self.member = self.shelf.on_loan.pop(self.title)\n        self.shelf.available.add(self.title)\n\n    def undo(self) -> None:\n        self.shelf.available.remove(self.title)\n        self.shelf.on_loan[self.title] = self.member\n\n    def __str__(self) -> str:\n        return f\"return {self.title}\"", "note": "A command carries everything needed to do the action and to reverse it. `Return` learns which member had the book when it runs, and keeps that for `undo`."},
 {"code": "\n\nclass Desk:\n    def __init__(self):\n        self.history: list[Command] = []\n\n    def run(self, command: Command) -> None:\n        command.execute()\n        self.history.append(command)\n        print(\"did:  \", command)\n\n    def undo_last(self) -> None:\n        command = self.history.pop()\n        command.undo()\n        print(\"undid:\", command)", "note": "The invoker. It runs commands and remembers them, and undo is popping the last one. It has no idea what lending or returning means."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf([\"Dom Casmurro\", \"Vidas Secas\"])\n    desk = Desk()\n    desk.run(Lend(shelf, \"Dom Casmurro\", \"Bia\"))\n    desk.run(Lend(shelf, \"Vidas Secas\", \"Caio\"))\n    desk.run(Return(shelf, \"Dom Casmurro\"))\n    print(shelf.report())\n    desk.undo_last()\n    desk.undo_last()\n    print(shelf.report())", "note": "Three actions, then two undone in reverse order. The shelf ends where it was after the first loan."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 command.py
did:   lend Dom Casmurro to Bia
did:   lend Vidas Secas to Caio
did:   return Dom Casmurro
available ['Dom Casmurro'], on loan {'Vidas Secas': 'Caio'}
undid: return Dom Casmurro
undid: lend Vidas Secas to Caio
available ['Vidas Secas'], on loan {'Dom Casmurro': 'Bia'}
```

Undo is the classic use, and not the only one. A list of command objects can be queued for later,
written to a log and replayed, sent to another process, or grouped into one larger command that runs
or undoes several together. **Once a request is an object, everything you can do with objects you
can do with requests.** Lesson 8 builds on this when it separates commands from queries, and
lesson 9 keeps the record of what happened as the system's truth.

## State: one object, different rules in each situation

A copy of a book can be on the shelf, out on loan, or on the hold shelf waiting for the member who
reserved it. What `lend` should do depends entirely on which. Written with a status field, every
method becomes a ladder of `if self.status == ...`, and adding a situation means editing every
ladder.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-state\" aria-label=\"A state diagram of one copy of a book with three states: Available, OnLoan and OnHold. From Available, lend goes to OnLoan and reserve goes to OnHold. From OnLoan, give_back goes to Available when nobody is waiting and to OnHold when somebody is; reserve stays in OnLoan and remembers who is waiting. From OnHold, lend by the member it is held for goes to OnLoan. Every other request in a state is refused.\"><defs><marker id=\"l06-state-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"25.0\" y=\"92.0\" width=\"150.0\" height=\"46.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Available</text><rect x=\"285.0\" y=\"92.0\" width=\"150.0\" height=\"46.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OnLoan</text><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">remembers who waits</text><rect x=\"545.0\" y=\"92.0\" width=\"150.0\" height=\"46.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OnHold</text><text x=\"620.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">for one member</text><path d=\"M175.0 104.0 L283.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"229.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend</text><path d=\"M283.0 128.0 L177.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"229.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back</text><text x=\"229.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">nobody waiting</text><path d=\"M435.0 115.0 L543.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"489.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back</text><text x=\"489.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">somebody waiting</text><path d=\"M100.0 92.0 L100.0 46.0 L620.0 46.0 L620.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">reserve</text><path d=\"M620.0 138.0 L620.0 190.0 L360.0 190.0 L360.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"490.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend</text><text x=\"490.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">by the member it is held for</text><text x=\"100.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">anything else:</text><text x=\"100.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">Refused, with the reason</text></svg>", "caption": "One copy, three situations. Each arrow is a method that moves the copy on; each missing arrow is a refusal with a reason."}
```

```schooling-example
{"language": "python", "file": "state.py", "parts": [
 {"code": "# state.py\nclass Refused(Exception):\n    pass", "note": "One exception for every refusal, carrying the reason in words."},
 {"code": "\n\nclass Available:\n    def lend(self, copy, member):\n        copy.state = OnLoan(member)\n\n    def give_back(self, copy):\n        raise Refused(\"it is already on the shelf\")\n\n    def reserve(self, copy, member):\n        copy.state = OnHold(member)\n\n    def __str__(self):\n        return \"available\"\n\n\nclass OnLoan:\n    def __init__(self, member, waiting=None):\n        self.member, self.waiting = member, waiting\n\n    def lend(self, copy, member):\n        raise Refused(f\"it is out with {self.member}\")\n\n    def give_back(self, copy):\n        copy.state = OnHold(self.waiting) if self.waiting else Available()\n\n    def reserve(self, copy, member):\n        if self.waiting:\n            raise Refused(f\"{self.waiting} reserved it first\")\n        copy.state = OnLoan(self.member, waiting=member)\n\n    def __str__(self):\n        extra = f\", {self.waiting} waiting\" if self.waiting else \"\"\n        return f\"on loan to {self.member}{extra}\"\n\n\nclass OnHold:\n    def __init__(self, member):\n        self.member = member\n\n    def lend(self, copy, member):\n        if member != self.member:\n            raise Refused(f\"it is held for {self.member}\")\n        copy.state = OnLoan(member)\n\n    def give_back(self, copy):\n        raise Refused(\"it was never lent\")\n\n    def reserve(self, copy, member):\n        raise Refused(f\"it is held for {self.member}\")\n\n    def __str__(self):\n        return f\"on hold for {self.member}\"", "note": "Each situation is a class with the same three methods. A method either moves the copy to its next state or refuses, and the rules for one situation sit together."},
 {"code": "\n\nclass Copy:\n    def __init__(self, title):\n        self.title, self.state = title, Available()\n\n    def lend(self, member):\n        self.state.lend(self, member)\n\n    def give_back(self):\n        self.state.give_back(self)\n\n    def reserve(self, member):\n        self.state.reserve(self, member)", "note": "The context. It holds the current state and forwards each call to it, and it contains no `if` about status at all."},
 {"code": "\n\nif __name__ == \"__main__\":\n    copy = Copy(\"Torto Arado\")\n    steps = [(\"lend\", \"Bia\"), (\"reserve\", \"Caio\"), (\"lend\", \"Duda\"), (\"give_back\",),\n             (\"lend\", \"Duda\"), (\"lend\", \"Caio\"), (\"give_back\",), (\"give_back\",)]\n    for action, *who in steps:\n        label = f\"{action} {' '.join(who)}\".strip()\n        try:\n            getattr(copy, action)(*who)\n            print(f\"{label:<14} -> {copy.state}\")\n        except Refused as err:\n            print(f\"{label:<14} refused: {err}\")", "note": "A day in the life of one copy, including three requests the rules refuse."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 state.py
lend Bia       -> on loan to Bia
reserve Caio   -> on loan to Bia, Caio waiting
lend Duda      refused: it is out with Bia
give_back      -> on hold for Caio
lend Duda      refused: it is held for Caio
lend Caio      -> on loan to Caio
give_back      -> available
give_back      refused: it is already on the shelf
```

Every refusal names its reason, and each reason lives in the one class where it applies. A fourth
situation, say a copy sent away for repair, is a new class plus the transitions into it, and the
three existing classes change only where a transition leads to the new one.

## State and strategy are the same shape

Both are a context holding an object behind an interface and delegating to it. The difference is
who changes the object. **A strategy is chosen from outside and stays until somebody swaps it; a
state replaces itself as a result of the calls it handles.** `WaitingList` never changes its own
ordering, and `Copy` never has its state set by a caller.

For a handful of states and a few methods, a dictionary of allowed transitions or a `match`
statement is often clearer than a class per state. The pattern earns its place when each state has
real behaviour of its own, as `OnLoan` does with its waiting member, and when states are added
over time.
