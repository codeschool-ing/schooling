---
title: Choosing, and when ETL is still right
version: 1
---

**Load first unless you have a reason not to.** That is the default this course takes, and the
argument is the last three sections: raw rows answer tomorrow's question, reproduce yesterday's
report, and let a bad transformation be fixed and rerun without asking the source again.

The reasons not to are real, and they are worth knowing by name:

| reason | what it looks like | why it points to ETL |
|---|---|---|
| **the data must not land** | customer e-mails, card numbers, health data | a column that was never loaded is a column you never have to protect, export or erase |
| **the transform is not SQL** | parse a PDF invoice, call a geocoding API, resize a cover image | the warehouse cannot do it, so it happens outside anyway |
| **the destination is weak** | an operational database, a spreadsheet, a small server | loading raw rows into it costs what the warehouse would have absorbed |
| **the volume is absurd** | a sensor sending a reading a millisecond | aggregate on the way, or the raw layer costs more than the answers |

## The first row is the one to take seriously

Ponto Final's customers asked for their e-mail addresses to be used for receipts, not for a
warehouse. A raw layer that copies `customers` whole now holds five thousand e-mail addresses in a
second place. Brazilian law — the LGPD — gives each of those people the right to ask for them to be
erased, from **every** place they are kept. A pipeline that drops `email` on the way in, or replaces it with a
hash, removes the problem before it exists. **That is ETL, and for that column it is the right
call** even in a warehouse that loads everything else raw.

So in practice most pipelines are both: **extract, a light transform that removes what must not
land, load, and then the real transformation inside the warehouse.** The letters are less useful
than the question behind them — where does each piece of work belong, and what does putting it
there cost?

Lesson 3 starts that question at the beginning, with the four kinds of source a pipeline extracts
from and what each one does to the extraction.
