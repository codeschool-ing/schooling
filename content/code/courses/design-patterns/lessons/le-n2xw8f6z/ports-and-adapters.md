---
title: Ports and adapters, the idea
version: 1
---

**Ports and adapters is dependency inversion applied to a whole application: the rules sit in the
middle, every conversation with the outside world goes through a port the rules define, and each
technology is an adapter plugged into a port.** Alistair Cockburn described it in 2005 and drew it
as a hexagon, which is why it is also called the hexagonal architecture. The hexagon has no meaning
beyond leaving room to draw several ports.

The usual misunderstanding is that it is a folder layout, `domain/`, `ports/`, `adapters/`, that a
project adopts on its first day. The folders are optional. The architecture is one rule about
imports, the one the last section checked with `grep`: nothing in the middle imports anything at
the edge.

## Two kinds of port

The last section built one port, `Notifier`. The rules call it, so the conversation goes outward;
Cockburn calls this a **driven** port, and the e-mail and SMS classes are driven adapters. The
other direction exists too. Something has to call the rules: a scheduled job, a web request, a
person at a terminal. That side is a **driving** port, and the code that turns a request from the
outside into a call on the rules is a driving adapter.

`main.py` was already one, a very plain driving adapter that runs on a fixed date. Here is a second,
for the desk staff, who type the date at a terminal and want the notices by text message:

```python
# cli.py
import sys
from datetime import date

from adapters import SmsNotifier
from main import LOANS
from notices import OverdueNotices

today = date.fromisoformat(sys.argv[1])
notifier = SmsNotifier({
    "Bia": "+55 11 5550-0142",
    "Caio": "+55 11 5550-0177",
    "Duda": "+55 11 5550-0103",
})
print(OverdueNotices(notifier).send(LOANS, today), "notices sent")
```

```
ana@laptop:~/patterns/solid-2$ python3 cli.py 2026-03-25
SMS to +55 11 5550-0142: 'Dom Casmurro' is 9 days late, 450 cents so far
SMS to +55 11 5550-0103: 'Vidas Secas' is 2 days late, 100 cents so far
2 notices sent
```

A different date, a different driven adapter and a different driving one, and `notices.py` was not
touched. On 25 March Dom Casmurro is nine days late, Vidas Secas two, and Iracema is still on
time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l04-ports\" aria-label=\"The rules in the middle, as notices.py with OverdueNotices, and a Notifier port on its right edge. On the left, the driving side: main.py and cli.py each call into the rules. On the right, the driven side: the rules call out through the Notifier port to EmailNotifier, to SmsNotifier, and in a test to Recording. Nothing in the middle imports anything at the edges.\"><defs><marker id=\"l04-ports-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">driving side</text><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">driven side</text><rect x=\"260.0\" y=\"80.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">notices.py</text><text x=\"360.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the rules</text><rect x=\"430.0\" y=\"122.0\" width=\"80.0\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">Notifier</text><rect x=\"50.0\" y=\"85.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.py</text><path d=\"M170.0 100.0 L256.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"50.0\" y=\"165.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cli.py</text><path d=\"M170.0 180.0 L256.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"65.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EmailNotifier</text><path d=\"M510.0 140.0 L535.0 140.0 L535.0 80.0 L556.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"125.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SmsNotifier</text><path d=\"M510.0 140.0 L535.0 140.0 L535.0 140.0 L556.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"185.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"625.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Recording</text><path d=\"M510.0 140.0 L535.0 140.0 L535.0 200.0 L556.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><text x=\"625.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">in a test</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nothing in the middle imports anything at the edges</text></svg>", "caption": "Ports and adapters: the driving adapters call the rules, and the rules reach every driven adapter through a port they own."}
```

## What the shape buys, and what it costs

Each adapter can be replaced alone. A web form instead of the terminal is a new driving adapter; a
real SMS gateway instead of `print` is a new driven one. The rules can be tested from the driving
side by calling them directly, and from the driven side with a recording double, which is exactly
what `test_notices.py` did.

The cost is a port for every kind of conversation, and code to translate at every edge: the
terminal's string becomes a `date`, the rules' text becomes whatever the gateway's API wants. For a
script that sends one kind of notice, that translation is most of the program. The shape pays when
the rules are substantial and the edges are several or likely to change.

This lesson stops at the idea. `architecture-modeling`, the course after this one, draws ports and
adapters as models of whole systems; lesson 12 of this course puts a repository behind a port; and
lesson 15 meets the same shape again as the functional core with an imperative shell around it.
