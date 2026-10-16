---
title: "CAP: what a broken link forces"
version: 1
---

**When the network between two copies of your data breaks, each side has to choose: answer and
risk disagreeing with the other side, or refuse until it can be sure.** That is the CAP theorem,
conjectured by Eric Brewer in 2000 and proved by Seth Gilbert and Nancy Lynch in 2002, and
`architecture` lesson 8 takes it apart properly. This section is about what the choice looks like
in the code you write, because it is there, in an `if`, and somebody has to decide what it says.

The common misreading is "pick two of three", as if a system could choose to have consistency and
availability and simply skip partitions. A partition is not something you choose. Cables are cut,
a router reboots, a data centre loses its uplink. **The choice CAP describes only exists while the
network is broken, and you make it in advance, in code, for the day it happens.**

The library opens a second branch in Vila Madalena. Each branch keeps a copy of the stock so the
desk can work fast, and Centro's copy is the one the library treats as the truth. One copy of a
book is left, the link between the branches goes down, and a member walks into each branch:

```schooling-example
{"language": "python", "file": "branches.py", "parts": [
 {"code": "# branches.py\nclass Refused(Exception):\n    pass\n\n\nclass Branch:\n    def __init__(self, name: str, primary: bool):\n        self.name = name\n        self.primary = primary\n        self.copies = 1\n        self.loans: list[str] = []\n        self.peer: \"Branch | None\" = None\n        self.link_up = True", "note": "A branch keeps its own copy of the count and the loans. Centro is the primary: its copy is the one the library treats as the truth."},
 {"code": "\n    def lend(self, member: str, mode: str) -> None:\n        if mode == \"CP\" and not self.primary and not self.link_up:\n            raise Refused(f\"cannot reach {self.peer.name}, try again later\")\n        if self.copies == 0:\n            raise Refused(\"no copy left\")\n        self.copies -= 1\n        self.loans.append(member)\n        if self.link_up:\n            self.peer.copies, self.peer.loans = self.copies, list(self.loans)", "note": "The whole of CAP is in the first `if`. In `CP` mode a branch that cannot reach the primary refuses; in `AP` mode it lends from the copy it has. While the link is up, every change is sent to the other branch at once."},
 {"code": "\n\ndef pair() -> tuple[Branch, Branch]:\n    centro, vila = Branch(\"Centro\", primary=True), Branch(\"Vila Madalena\", primary=False)\n    centro.peer, vila.peer = vila, centro\n    return centro, vila"},
 {"code": "\n\nif __name__ == \"__main__\":\n    for mode in (\"CP\", \"AP\"):\n        print(mode)\n        centro, vila = pair()\n        centro.link_up = vila.link_up = False\n        for branch, member in ((centro, \"Bia\"), (vila, \"Caio\")):\n            try:\n                branch.lend(member, mode)\n                print(f\"  {branch.name} lends the copy to {member}\")\n            except Refused as err:\n                print(f\"  {branch.name} refuses {member}: {err}\")\n        loans = sorted(set(centro.loans) | set(vila.loans))\n        print(f\"  link back up: loans {loans} against 1 copy\")", "note": "The link is cut before anyone arrives. Bia asks at Centro, Caio at Vila Madalena, for the one copy both branches believe they have."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 branches.py
CP
  Centro lends the copy to Bia
  Vila Madalena refuses Caio: cannot reach Centro, try again later
  link back up: loans ['Bia'] against 1 copy
AP
  Centro lends the copy to Bia
  Vila Madalena lends the copy to Caio
  link back up: loans ['Bia', 'Caio'] against 1 copy
```

In `CP` mode, Centro still lends. It is the primary, so its answer is the truth whatever the other
branch thinks. Vila Madalena cannot know whether the copy is still there, so it refuses Caio, and
when the link comes back there is one loan for one copy. **Consistency was kept by making one side
unavailable, and the other side carried on.**

In `AP` mode both branches lend. Each one served its member at once, and when the link comes back
the library holds two loans against one copy. Nothing in the program is broken. That outcome is the
price of availability, and somebody now has to phone Caio.

## What each answer costs in code

A refusal is an exception, and an exception has to be handled by somebody. In `CP` mode, the desk
screen needs a sentence for "cannot reach Centro, try again later", a member who is turned away,
and a retry. That code exists only because of the choice.

Accepting costs a different kind of code, and it runs later. Somebody has to find the conflict when
the link returns, decide who keeps the copy and tell the other member. Lesson 9's projections met a
milder form of the same thing, a read model that lags; here two writes disagree, and no amount of
waiting reconciles them on its own.

## The two Cs are different words

The C in CAP and the C in ACID share a letter and almost nothing else, and mixing them up makes
both theorems sound wrong.

| | ACID's C | CAP's C |
|---|---|---|
| it means | a transaction leaves the data valid: constraints and rules hold | every read sees the most recent write, as if there were one copy |
| it is about | one database, and the rules on its data | several copies of the data, and whether they agree |
| in this lesson | the foreign key refusing `m-009` in `reserve.py` | Vila Madalena refusing Caio rather than answer from a stale count |

CAP's C is what the literature calls *linearizability*. A system can have every ACID property on
each node and still fail CAP's C between nodes, which is exactly what the `AP` run shows: each
branch's own data is valid, and the two disagree.
