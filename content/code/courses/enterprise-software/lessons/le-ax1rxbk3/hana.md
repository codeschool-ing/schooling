---
title: HANA, and why S/4HANA is not an upgrade
version: 1
---

On her third day with the SAP team Joana asked the question everybody asks: when does Serra Alta
upgrade to S/4HANA? Edson's answer was that it doesn't. **S/4HANA is not ECC on a faster database;
it is the suite rewritten around a database that changed what the data model needed to be.** Moving
to it is a project of years, with its own decisions about history, about custom code and about every
interface that touches SAP. To see why, start with the database.

## A database that keeps columns together

HANA is SAP's own database, and it differs from the databases ECC usually ran on in two ways.

It is **in memory**: the working copy of the data is held in main memory, rather than on disk with a
cache in front. It is not volatile for that. HANA writes a log of every change and saves its memory
to disk at intervals, so a restart reloads the data and loses nothing that was committed.

And it is **column-oriented**. A conventional database stores a table row by row: every field of
one order line sits together on disk. A column store keeps each column together instead: all the
quantities in one place, all the plants in another, all the material numbers in a third.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-columns\" aria-label=\"The same three order lines stored two ways. Each line has four fields: order, material, plant and quantity. In a row store the twelve values lie one row after another, so the three quantities are scattered and summing them means reading every row whole. In a column store the values lie one column after another, so the three quantities sit in one block and the sum reads only that block. The plant column is stored as a dictionary of three plants and a two-bit code per line.\"><text x=\"42.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">row store: one row after another</text><rect x=\"42.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"67.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4711</text><rect x=\"94.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"119.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"146.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"171.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"198.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1200</text><rect x=\"258.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4712</text><rect x=\"310.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"335.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BUT-200</text><rect x=\"362.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"387.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LV01</text><rect x=\"414.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"439.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">300</text><rect x=\"474.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4713</text><rect x=\"526.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"551.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"578.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"603.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"630.0\" y=\"48.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"655.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">950</text><text x=\"42.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">to sum the quantities, every row is read whole</text><text x=\"42.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">column store: one column after another</text><rect x=\"42.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"67.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4711</text><rect x=\"94.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"119.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4712</text><rect x=\"146.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"171.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4713</text><rect x=\"206.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"231.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"258.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BUT-200</text><rect x=\"310.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"335.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UHT-1L</text><rect x=\"370.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"395.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"422.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"447.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LV01</text><rect x=\"474.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01</text><rect x=\"534.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"559.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1200</text><rect x=\"586.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"611.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">300</text><rect x=\"638.0\" y=\"158.0\" width=\"50.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"663.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">950</text><text x=\"42.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">to sum the quantities, one block is read</text><text x=\"42.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the plant column, compressed:</text><text x=\"242.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JF01=0  BA01=1  LV01=2</text><text x=\"412.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">then one 2-bit code a line:</text><text x=\"602.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0 2 0</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the field names, in order: order, material, plant, quantity</text></svg>", "caption": "One table, two layouts. A row store keeps a record together; a column store keeps a field together, which is what a sum over millions of lines wants."}
```

**A row store is fast at touching one record; a column store is fast at reading one field across
millions of them.** Creating a sales order, or reading one back, wants the whole row, and a row
store hands it over in one place. A question such as "how many litres of UHT milk did each plant
sell last quarter" wants three fields out of forty, across every line. A row store has to read all
forty to get at the three; a column store reads the three and ignores the rest.

Columns also compress well, because a column holds one kind of value and repeats it. Take a sales
order line table at Serra Alta with 40 million lines. Its plant column holds one of three values,
since only Juiz de Fora, Barbacena and Lavras run on SAP. Stored as four-character text, that column
takes 40,000,000 × 4 bytes, which is 160 MB. Replace each value with a number into a short
dictionary of the three plants, and two bits are enough for each line: 40,000,000 × 2 bits is
80,000,000 bits, or 10 MB. The figures are illustrative rather than HANA's exact storage format, but
the principle, **a dictionary of distinct values and a compact code per row**, is how column stores
fit large tables into memory.

## What the data model no longer needs

ECC was designed for databases that could not add up millions of line items while a user waited. So
every posting did more than record itself. It wrote the line item, then updated a *totals* table
holding running sums per account and period, then wrote rows into *index* tables that existed only
to find things quickly, such as a customer's open items. One goods receipt or one invoice touched
several tables, all kept in step by SAP's code.

On a column store held in memory, the sums can be computed from the line items when they are asked
for. S/4HANA was built on that assumption, and SAP used it to remove a large part of ECC's data
model.

| area | in ECC | in S/4HANA |
|---|---|---|
| finance and controlling | line items kept separately for FI and for CO, plus totals tables such as `GLT0` and index tables such as `BSID` and `BSAK` | one line-item table, `ACDOCA`, the *Universal Journal*; totals and indexes computed when read |
| inventory | material documents in a header table and an item table, `MKPF` and `MSEG` | one table, `MATDOC`, the one lesson 1 met |
| sales documents | status kept in tables of its own, `VBUK` and `VBUP` | status fields in the order tables themselves |
| customers and suppliers | separate customer and vendor master records | one *business partner*, mandatory for both |
| material number | up to 18 characters | up to 40 characters |
| database | several supported | HANA only |

**The Universal Journal is the change finance people care about.** In ECC, financial accounting and
controlling kept separate records of the same events, and Serra Alta's month-end close includes a
reconciliation between them that Marcos Teles's team runs by hand. With one line-item table for both,
they agree by construction.

The old table names did not all vanish. Many survive as *compatibility views* computed from the new
tables, so ABAP code that reads `BSID` still gets an answer. Code that writes to them fails, and so
does code that assumes a material number fits in 18 characters, or that creates a customer without a
business partner. Each of those is somewhere in Serra Alta's 1,800 Z objects, and some of
them are in the interfaces too: an EDI map that cuts material numbers at 18 characters works until
the first longer one is created.

## The date that sets the agenda

SAP publishes how long it supports each release. For ECC 6.0 on enhancement package 6 or later, which
is where Serra Alta is, **mainstream maintenance ends on 31 December 2027**. SAP offers optional
extended maintenance until the end of 2030 for an additional fee. After that, ECC passes into what SAP
calls customer-specific maintenance, which no longer delivers new legal changes.

That last clause is the one that matters in Brazil. **An ERP that stops receiving legal changes stops
being able to invoice.** Brazil's consumption-tax reform phases new taxes in between 2026 and 2033,
and the NF-e layout changes with it; a Serra Alta that could not issue a valid NF-e could not ship a
pallet of butter. "Stay on ECC" is therefore an option with an end date, not an option.

Joana did the arithmetic on a whiteboard for Regina Fontes. Extended maintenance buys three years,
from 1 January 2028 to 31 December 2030, and each of them costs more than a year of mainstream
maintenance did. It buys time to do the project; it does not make the project smaller.

## Three ways across

SAP and its partners describe three broad approaches, and each one is a different answer to the
question "what do we keep?".

| approach | what happens | what is kept | what it costs you |
|---|---|---|---|
| greenfield, a new implementation | S/4HANA is implemented from scratch and the business processes are redesigned | master data, open items and balances, migrated into the new system | the history stays behind in the old system or an archive, and every custom object is either rewritten or dropped |
| brownfield, a system conversion | the existing system is converted in place: the database moved to HANA, the data converted to the new model | everything: history, customising, custom code | each item on SAP's list of changes for the target release has to be dealt with before the conversion runs |
| selective data transition | a new system is built from the old one's configuration, then chosen data and history are moved into it | what you choose, for example one company or the last three years | specialist tools and a partner who has done it before |

**None of the three is an upgrade**, and the difference between them is mostly a difference about
data. Lesson 14 is about moving data between systems, and it comes back to these three choices from
that side.

## What happens to the 1,800 objects

SAP publishes a *Simplification List* for each S/4HANA release: every place where the new data model
or the new functionality differs from ECC. Its ABAP Test Cockpit can check custom code against it,
and the first run against Serra Alta's system listed findings in the thousands, each one a
place where a Z object reads, writes or assumes something that changed.

This is the bill for fifteen years without the clean core that lesson 1 described, arriving all at
once. The cheapest finding to fix is in code nobody runs. Edson's team switched on SAP's usage
logging in January 2026, and by October about 650 of the 1,800 objects had not run once. **Custom code that has
not run in a full business cycle is a candidate for deletion, not for conversion**, and deleting it
before the project starts shrinks every estimate built after it. The cycle matters: a report used
only at the annual close looks dead for eleven months, and the logging has to cover a whole year
before anybody deletes on its strength.

What is left gets triaged. Some objects exist because ECC lacked something that S/4HANA now has as
standard, and those can go back to standard. Some encode how Serra Alta works and have to be
rewritten for the new model. And some, like the program that loads Coleta's file, are interfaces,
which is where the next section starts.

Joana's mistake on day three was a useful one. Treating the move as an upgrade would have put it in
next year's IT budget beside the database licences. Treated as what it is, it becomes a decision
for Regina, Marcos and the board about which approach to take and how much history to carry, and
whatever they pick, every interface into SAP is on the list of things to change.
