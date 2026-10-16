---
title: Events as the record
version: 1
---

In an ordinary orders table, adding an item to an order runs an `UPDATE`, and the order's row now says
what is in it. What it said a minute ago is gone. **Event sourcing** keeps the other half: instead of
storing the current state, it stores **every change as an event**, in order, and never changes or
deletes one. The current state is whatever you get by replaying them.

Place an order, change it a few times, and pay for it:

```
ana@vm:~/lab/events$ $O place o-1
o-1 v1: OrderPlaced
ana@vm:~/lab/events$ $O add o-1 coffee 2
o-1 v2: ItemAdded {"product": "coffee", "units": 2}
ana@vm:~/lab/events$ $O add o-1 tea 1
o-1 v3: ItemAdded {"product": "tea", "units": 1}
ana@vm:~/lab/events$ $O remove o-1 tea
o-1 v4: ItemRemoved {"product": "tea"}
ana@vm:~/lab/events$ $O add o-1 rice 3
o-1 v5: ItemAdded {"product": "rice", "units": 3}
ana@vm:~/lab/events$ $O pay o-1
o-1 v6: OrderPaid
ana@vm:~/lab/events$ $O add o-1 tea 1
o-1: is paid, cannot add
```

Each command loaded the order, checked the rules against it, and appended one event with the next
version number. The last command was refused by a rule: the order was paid. Now look at what the
database holds:

```
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT position, stream, version, type, data FROM events'
 position | stream | version |    type     |               data                
----------+--------+---------+-------------+-----------------------------------
        1 | o-1    |       1 | OrderPlaced | {}
        2 | o-1    |       2 | ItemAdded   | {"units": 2, "product": "coffee"}
        3 | o-1    |       3 | ItemAdded   | {"units": 1, "product": "tea"}
        4 | o-1    |       4 | ItemRemoved | {"product": "tea"}
        5 | o-1    |       5 | ItemAdded   | {"units": 3, "product": "rice"}
        6 | o-1    |       6 | OrderPaid   | {}
(6 rows)
```

That table is the whole truth about the order, and there is **no row anywhere that says "o-1 is paid
with two coffees and three rice"**. `show` works it out:

```
ana@vm:~/lab/events$ $O show o-1
o-1 at v6: paid, coffee x2, rice x3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The stream of events for order o-1, as six boxes in a row: v1 OrderPlaced, v2 ItemAdded coffee 2, v3 ItemAdded tea 1, v4 ItemRemoved tea, v5 ItemAdded rice 3, v6 OrderPaid. Below, the state obtained by replaying them: paid, coffee 2, rice 3. A bracket under the first three shows that replaying only those gives the order as it was at version 3: open, coffee 2, tea 1.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"24\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><text x=\"76\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">OrderPlaced</text><rect x=\"137\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"189\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v2</text><text x=\"189\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemAdded</text><text x=\"189\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">coffee 2</text><rect x=\"250\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"302\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v3</text><text x=\"302\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemAdded</text><text x=\"302\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tea 1</text><rect x=\"363\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v4</text><text x=\"415\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemRemoved</text><text x=\"415\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tea</text><rect x=\"476\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"528\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v5</text><text x=\"528\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ItemAdded</text><text x=\"528\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rice 3</text><rect x=\"589\" y=\"40\" width=\"104\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"641\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">v6</text><text x=\"641\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">OrderPaid</text><path d=\"M24 118 L24 126 L362 126 L362 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"193\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">replay to v3: open, coffee 2, tea 1</text><rect x=\"200\" y=\"168\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">replay all: paid, coffee 2, rice 3</text></svg>", "caption": "The events are the record; the state is a calculation over them. Stop the calculation earlier and you get the state at that moment."}
```

The events are named in the past tense, `ItemAdded` rather than `AddItem`, and that is a rule rather
than a style. A **command** is a request that can be refused, as the last `add` was. An **event** is a
fact that has already happened and is never refused or changed: the tea was added at version 3, and the
removal at version 4 is a second fact, not a correction of the first.

Accountants have worked this way for centuries. A ledger is never edited; a mistake is corrected by a
new entry, and the balance is a sum over the entries. Lesson 7's payments are already shaped like this;
event sourcing applies the same shape to everything.
