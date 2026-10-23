---
title: Choosing a style for each integration
version: 1
---

The four styles are not a ranking, and choosing between them is not a matter of taste. **Each
integration has a few facts that decide its style: how fresh the data has to be, how much of it there
is, who has to be up, and how a failure would show itself.** Write those facts down for a row on the
map and the style mostly chooses itself. When it does not, the disagreement is usually about a fact,
and that is a better argument to have.

Joana's map, when she had finished classifying it, looked like this. The amber part of each bar is the
rows for which nobody could say how a failure would be noticed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-map-count\" aria-label=\"Horizontal bars counting the 110 integrations on Joana's map by style. File transfer, 41, 20 of them through the ESB, 14 with no known way to notice a failure. Shared database, 17, none through the ESB, 15 with no known way to notice a failure. API, 33, 31 through the ESB, 4 with no known way to notice a failure. Event or message, 19, all through the ESB, 5 with no known way to notice a failure. In all, 70 go through the ESB and 38 have no known way to notice a failure, drawn in amber at the start of each bar.\"><text x=\"14.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">file transfer</text><text x=\"14.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 through the ESB</text><rect x=\"190.0\" y=\"29.0\" width=\"410.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"29.0\" width=\"140.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"260.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">14</text><text x=\"610.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">41</text><text x=\"14.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shared database</text><text x=\"14.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 through the ESB</text><rect x=\"190.0\" y=\"79.0\" width=\"170.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"79.0\" width=\"150.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"265.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">15</text><text x=\"370.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17</text><text x=\"14.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">API</text><text x=\"14.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31 through the ESB</text><rect x=\"190.0\" y=\"129.0\" width=\"330.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"129.0\" width=\"40.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"210.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4</text><text x=\"530.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">33</text><text x=\"14.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">event</text><text x=\"14.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19 through the ESB</text><rect x=\"190.0\" y=\"179.0\" width=\"190.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"179.0\" width=\"50.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"215.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5</text><text x=\"390.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">19</text><rect x=\"190.0\" y=\"236.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"220.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nobody could say how a failure would be noticed</text><text x=\"190.0\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">110 integrations in all; 70 through the ESB, 40 point to point</text></svg>", "caption": "Joana's map by style. The shared database is the smallest group and the worst watched: almost none of its links was ever designed as an integration."}
```

The database links are the worst-watched style by a distance: 15 of 17 had no way of noticing a
failure, because nobody had designed them as integrations in the first place. The calls were the
best watched, 4 of 33, because a call that fails does so at once and in front of somebody.

## The decision table

| | file | shared database | API | event |
|---|---|---|---|---|
| freshness it gives | hours: as old as the last file | as fresh as the table | now | seconds, normally |
| volume it suits | large batches, cheaply | any, at the owner's expense | one item per call | many small facts |
| who must be up | nobody at the same time | the database | caller and everything in the chain | the broker |
| what it couples | the file's layout | the owner's tables and their meaning | the published contract, and time | the message's contract |
| how failure shows | a file that does not come, or comes incomplete | wrong answers, or a query that breaks after a change | an error or a timeout, at once, to somebody waiting | a growing lag, with no error |
| what it costs to run | a directory, a schedule and the controls | nothing visible, until a change | the availability of every hop | a broker, and somebody owning each topic |

Two rows deserve a second look. *How failure shows* is where the alarm has to go: on the missing file,
on the timeout, on the lag. And *what it costs to run* is why the cheapest-looking style in the
table, the shared database, is the one Joana wanted fewer of: its cost is not visible until the day it
is all paid at once.

## Six rows from the map

Joana took six rows that people at Serra Alta argued about, and decided each against the table.

**1. Coleta → SAP, the farms' daily litres. It stays a file.** SAP needs the litres for goods receipts
the next morning and for farm payment on the 10th of the month; nothing about it needs seconds.
Coleta writes files easily and calls nothing easily, and Sebastião retires in 2028, so a new interface
on IBM i is code that nobody will maintain. What changes is the controls: a trailer with the count and
the litres, checked before loading; a load that refuses a file it has seen; a reject file back to
Coleta; and the alarm at 01:30. Lesson 13 replaces Coleta itself, and at that point this file goes
with it.

**2. Portal B2B → SAP, stock at checkout. It stays a call, with a fallback.** A bakery is waiting and
the answer has to be current, so all three conditions for a call hold. What changed is the previous
section's: timeouts that shrink inward, no retries into a struggling SAP, and the Sunday behaviour
used whenever SAP is slow.

**3. SAP → Salesforce, invoices. It becomes an event.** The key account reps want to see an invoice on
the customer's record, nobody waits for it at that instant, and Salesforce is one of three consumers
of the same fact. The invoice-authorised topic from the previous section serves it, and the ESB flow
that called Salesforce for every invoice is retired.

**4. SAP ↔ the banks, CNAB 240. It stays a file, and that is not Serra Alta's choice to make.** The
bank defines the interface. Some banks now offer APIs for some of the same operations; for 1,900 farm
payments once a month, a file with batch totals and a *retorno* answer is well understood by both
sides, and the controls that matter are already in the standard. What Joana added to the map was the
missing alarm: a *retorno* file that has not arrived by 10:00 on payment day pages finance.

**5. SAP → Rota, how much milk each plant will take. It becomes an event.** Rota plans the trucks for
the next day, and to plan them it needs to know where to deliver the milk: how many litres each plant
will take, from the production plan in SAP. Today SAP writes that as a file at 16:00. The trouble is
the night: when a dryer broke down at Barbacena in July, the plant could take 200,000 litres less, and
the dispatchers found out by phone, two hours later. Published as an event whenever a plant's intake plan changes, carrying the whole plan for that plant, the 16:00 file becomes simply the first event of the day. The dryer becomes another one, a minute after the planner enters it.

**6. Documentum → customers, certificates of analysis. It becomes an API.** Supermarket chains ask
for the certificate of a batch, and today Cláudia's team finds the PDF in Documentum and emails it by
hand, about 120 times a week. Only some customers want certificates, for some batches, at moments
nobody can predict, so sending every certificate to everybody would be a lot of traffic for nothing.
A call that takes a batch number and returns the certificate, served by a small service that reads
Documentum through its own interface (lesson 5), lets a chain's system or a person ask when they need
one. Somebody is waiting, the answer must be the current document, and the volume is small: the three
conditions again.

| integration | today | decided | the fact that decided it |
|---|---|---|---|
| Coleta → SAP litres | file | file, with controls | nobody waits; Coleta is retiring |
| Portal → SAP stock | call | call, with fallback | a bakery waits for a current answer |
| SAP → Salesforce invoices | chained calls through the ESB | event | three consumers of one fact, nobody waiting |
| SAP ↔ banks | CNAB file | CNAB file | the bank's standard |
| SAP → Rota plant intake | file at 16:00 | event | the plan changes at night |
| Documentum → customers certificates | email by hand | API | asked for on demand, by batch |

## What the table does not settle

Two things stay outside it.

**Who owns the integration.** Every row on the map needs a name in the owner column, and a style does
not supply one. An event topic without an owner is a schema that changes when somebody feels like it;
a file without an owner is the one whose password expires.

**The cost of changing.** A row that works, in a style the table would not choose, is not automatically
worth moving. Serra Alta has 17 database links, and Joana's plan moves 4 of them in the next year:
the ones that read SAP's tables and would break in the S/4HANA migration anyway. The others get an
owner, a note on the map and an alarm. **The map is a list of decisions to make, not a list of things
to rebuild**, and lesson 15 is about how to put a cost on the ones you do rebuild.

Once the styles are decided, the next questions are inside them. Lesson 10 takes the messaging style
apart: what a broker promises and what a consumer has to do about it. Lesson 11 names the patterns
that appear inside all four styles, such as the translator that turns a row into a business event and
the router that decides which consumer gets which message. With those names, the map can be drawn in
a vocabulary everybody on the integration team shares.
