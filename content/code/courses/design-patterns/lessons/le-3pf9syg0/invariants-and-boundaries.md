---
title: "Invariants and boundaries: one aggregate per transaction"
version: 1
---

**Two rules decide where an aggregate ends. Change one aggregate per transaction, and refer to
other aggregates by their id, never by holding the object.** Together they keep each aggregate
small enough to lock briefly, and they force a decision about every rule that spans two of them:
does it have to be true at every instant, or is it enough that it becomes true soon?

The wrong idea is that a rule involving two things means the two things belong in one aggregate.
"A copy is out to one member at a time" involves a copy and a member. Put copies inside members
and the copy has to be found inside whichever member holds it; put members inside copies and Bia
is spread across five aggregates. Neither works. **The copy is an aggregate of its own, with its
own rule, and lending is a conversation between two aggregates.**

## Two aggregates, one after the other

Here is the copy, holding the member's id rather than the member, and a `lend` that changes the
copy first and the member second:

```schooling-example
{"language": "python", "file": "copies.py", "parts": [
 {"code": "# copies.py\nfrom member import Member, Refused\n\n\nclass Copy:\n    def __init__(self, copy_id: str, isbn: str, kind: str):\n        self.id = copy_id\n        self.isbn = isbn\n        self.kind = kind\n        self.on_loan_to: str | None = None\n\n    def check_out(self, member_id: str) -> None:\n        if self.on_loan_to is not None:\n            raise Refused(f\"copy {self.id} is out to {self.on_loan_to}\")\n        self.on_loan_to = member_id\n\n    def check_in(self) -> None:\n        self.on_loan_to = None", "note": "A copy is an aggregate of its own: it has its own id, and its own rule, that it is out to one member at a time. It refers to the member by id, as a string, never by holding the `Member`."},
 {"code": "\n\ndef lend(copy: Copy, member: Member, today) -> None:\n    copy.check_out(member.id)\n    try:\n        member.borrow(copy.id, copy.kind, today)\n    except Refused:\n        copy.check_in()\n        raise", "note": "Lending touches two aggregates, one after the other. If the member refuses, the copy is checked back in: a correction, made by code, after the first change has already happened."},
 {"code": "\n\nif __name__ == \"__main__\":\n    from datetime import date\n    day = date(2026, 3, 2)\n    bia, caio = Member(\"m-001\", \"Bia\"), Member(\"m-002\", \"Caio\")\n    for n in range(1, 6):\n        lend(Copy(f\"C-{n:04d}\", \"978-65-5555-001-6\", \"book\"), bia, day)\n    extra = Copy(\"C-0100\", \"978-65-5555-002-3\", \"book\")\n    for who in (bia, caio, bia):\n        try:\n            lend(extra, who, day)\n            print(f\"{extra.id} lent to {who.name}\")\n        except Refused as err:\n            print(f\"refused for {who.name}: {err}\")\n        print(f\"  {extra.id} on loan to: {extra.on_loan_to}\")", "note": "Bia already has five loans. The same extra copy is offered to Bia, to Caio, and to Bia again."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 copies.py
refused for Bia: Bia already has 5 loans
  C-0100 on loan to: None
C-0100 lent to Caio
  C-0100 on loan to: m-002
refused for Bia: copy C-0100 is out to m-002
  C-0100 on loan to: m-002
```

Bia already has five loans. Offered the extra copy, the copy checks out to her, the member refuses,
and the copy is checked back in: `on loan to: None`. Caio gets it. When Bia asks again, the copy
itself refuses, because it is out to `m-002`. Each aggregate kept its own rule; neither had to know
the other's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-boundaries\" aria-label=\"Two aggregates, each inside a dashed boundary. On the left, the Member aggregate: the root Member, with fields id, name and owed, holds a list of Loan objects, each with copy_id and due, drawn with a filled diamond at the Member end. On the right, the Copy aggregate: a single root Copy with id, kind and on_loan_to. A dashed arrow labelled &quot;by id&quot; runs from Loan's copy_id to Copy, and another from Copy's on_loan_to back to Member. Outside code, at the bottom, has solid arrows only to the two roots, never to a Loan.\"><defs><marker id=\"l12-boundaries-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-boundaries-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 14 L350 14 L350 214 L20 214 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"185.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">Member aggregate</text><path d=\"M470 14 L700 14 L700 214 L470 214 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"585.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">Copy aggregate</text><rect x=\"40.0\" y=\"50.0\" width=\"130.0\" height=\"125.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«root»</text><text x=\"105.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Member</text><path d=\"M40.0 87.0 L170.0 87.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"98.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">id</text><text x=\"48.0\" y=\"112.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">name</text><text x=\"48.0\" y=\"127.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">owed: Money</text><path d=\"M40.0 138.5 L170.0 138.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"149.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">borrow()</text><text x=\"48.0\" y=\"164.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back()</text><rect x=\"220.0\" y=\"70.0\" width=\"110.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M220.0 92.5 L330.0 92.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"228.0\" y=\"103.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">copy_id</text><text x=\"228.0\" y=\"118.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">due</text><path d=\"M170.0 100.0 L220.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M170.0 100.0 L179.0 105.5 L188.0 100.0 L179.0 94.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><text x=\"275.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">0..5, inside</text><rect x=\"520.0\" y=\"60.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"71.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«root»</text><text x=\"590.0\" y=\"85.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Copy</text><path d=\"M520.0 97.0 L660.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"528.0\" y=\"108.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">id</text><text x=\"528.0\" y=\"122.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kind</text><text x=\"528.0\" y=\"137.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">on_loan_to</text><path d=\"M520.0 148.5 L660.0 148.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"528.0\" y=\"159.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">check_out()</text><path d=\"M330.0 92.0 L517.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12-boundaries-dp-ah-phosphor)\"></path><text x=\"420.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">by id</text><path d=\"M520.0 158.0 L173.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12-boundaries-dp-ah-phosphor)\"></path><text x=\"420.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">by id</text><rect x=\"260.0\" y=\"255.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">outside code: desk, use cases</text><path d=\"M300.0 255.0 L300.0 240.0 L105.0 240.0 L105.0 217.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-boundaries-dp-ah-paper-dim)\"></path><path d=\"M420.0 255.0 L420.0 240.0 L590.0 240.0 L590.0 217.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-boundaries-dp-ah-paper-dim)\"></path><text x=\"175.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">only through the roots</text></svg>", "caption": "Each aggregate keeps its own rule behind its root. Between aggregates there are ids, never references to the objects."}
```

## Instant or eventual

Look at what `lend` did when Bia was refused: for a moment, the copy said it was out to her while
she had no such loan. In this program the moment is two lines long. With each aggregate saved in
its own transaction, the moment could include a crash, and the correction would never run. So every
rule that crosses a boundary gets one of two answers:

| the rule must be true | how | in the library |
|---|---|---|
| at every instant | the two belong in one aggregate after all, or one transaction changes both and you accept the larger lock | rare; nothing in lending needs it |
| soon | change one aggregate, record an event, let a handler change the other, and repair when it fails | the copy and the member; the catalogue's "available" count |

**Most rules that cross a boundary are "soon" rules once somebody asks the business.** A librarian
does not need the copy and the member to agree within the same millisecond; she needs no copy lent
twice and no loan without a copy, and a minute of disagreement that a job repairs is fine. That is
lesson 10's choice per operation, made at the size of one aggregate. The next two sections give it
machinery: the repository saves one aggregate in one transaction, and domain events carry the
change to the next one.

## Why by id

`Copy.on_loan_to` is the string `m-002`, and `Loan.copy_id` is the string `C-0100`. Holding the
objects instead would let code reach from a copy into its member and change her, outside her root
and outside her transaction, which is exactly the second door the last section closed. An id is
also what survives storage: loading a member does not have to load every copy she has, and every
member who borrowed those copies, until the whole library is in memory.

Vaughn Vernon's *Implementing Domain-Driven Design* (2013) states these rules most plainly, and
adds a third worth repeating here: design small aggregates. The member above holds loans and
nothing else. Holds, payments and history can each be an aggregate of their own, joined by the
member's id.
