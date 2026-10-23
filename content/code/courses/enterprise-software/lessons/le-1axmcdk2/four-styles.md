---
title: Four ways for two systems to meet
version: 1
---

In her third month at Serra Alta, Joana asked a question nobody could answer: how many integrations
does the company have? Rui knew the ESB's flows. Edson knew which ABAP programs read files. Talita
knew what reached Salesforce. Nobody had all of it, so she built the list herself, in a spreadsheet,
one row per integration: from where, to where, what crosses, how often, who owns it, and how anybody
would notice that it had stopped.

It took five weeks and came to **110 rows**. The ESB's 70 message flows were the easy part, because
the ESB has a console that lists them. The other 40 were found by asking: a file Coleta pushes every
night, a Power BI report that reads a database directly, a table Rota writes and an ABAP job polls. **For 38 of the 110 rows, nobody could say how a failure would be noticed.** That column
turned out to be the most useful one in the sheet.

The other useful column was *style*. Every row on the map moves data in one of four ways, and the
way it moves decides most of what can go wrong with it.

## The four styles

Gregor Hohpe and Bobby Woolf, in *Enterprise Integration Patterns* (2003), open the book with four
integration styles. They are still the right four, twenty years and several technologies later,
because each one answers a different question about how two systems meet.

- *File transfer.* One system writes a file; the other reads it, later. Coleta's nightly file to
  SAP, the CNAB files exchanged with banks, the EDI messages with the supermarket chains.
- *Shared database.* Two systems read and write the same tables. At Serra Alta that is mostly
  one system reading another's tables directly, or a staging table one side writes and the other
  polls.
- *Remote procedure invocation*, which this lesson calls *by API*. One system calls the other and
  waits for the answer: a SOAP call through the ESB, a REST request from the Portal B2B.
- *Messaging*, which this lesson calls *by event*, because the use of it that matters most here is
  publishing a fact. One system sends a message to a broker, and whoever is interested receives it.
  IBM MQ carries Serra Alta's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l09-four-styles\" aria-label=\"Four rows, one per integration style, each with an example from Serra Alta and a column saying whether both sides must be up at once. File transfer: Coleta writes a file, written at 23:30, and SAP reads it at 02:00; both up at once: no. Shared database: Coleta writes its own tables and Rota reads them directly; only the database must be up. API: the Portal B2B sends a request to SAP and waits for the answer, which comes back; both up at once: yes. Event: SAP publishes a message to a broker, and any number of subscribers receive it; both up at once: no, the broker holds the message.\"><defs><marker id=\"l09-four-styles-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-four-styles-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"655.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">both up at once?</text><text x=\"14.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">file transfer</text><rect x=\"153.0\" y=\"53.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta</text><rect x=\"448.0\" y=\"53.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP</text><text x=\"655.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no</text><rect x=\"297.0\" y=\"53.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a file</text><path d=\"M258.0 70.0 L295.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M408.0 70.0 L446.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><text x=\"352.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">written 23:30, read 02:00</text><path d=\"M10.0 106.0 L710.0 106.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"14.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shared database</text><rect x=\"153.0\" y=\"125.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta</text><rect x=\"448.0\" y=\"125.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Rota</text><text x=\"655.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">only the database</text><rect x=\"297.0\" y=\"125.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta's tables</text><path d=\"M258.0 142.0 L295.0 142.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M446.0 142.0 L409.0 142.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><text x=\"352.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Rota reads them directly</text><path d=\"M10.0 178.0 L710.0 178.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"14.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">API</text><rect x=\"153.0\" y=\"197.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal B2B</text><rect x=\"448.0\" y=\"197.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP</text><text x=\"655.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">yes</text><path d=\"M258.0 207.0 L446.0 207.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M446.0 221.0 L258.0 221.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l09-four-styles-es-ah-paper-dim)\"></path><text x=\"352.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">request</text><text x=\"352.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the caller waits for the answer</text><path d=\"M10.0 250.0 L710.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"14.0\" y=\"286.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">event</text><rect x=\"153.0\" y=\"269.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP</text><rect x=\"456.0\" y=\"261.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"452.0\" y=\"265.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"448.0\" y=\"269.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">subscribers</text><text x=\"655.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no</text><rect x=\"297.0\" y=\"269.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broker</text><path d=\"M258.0 286.0 L295.0 286.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M408.0 286.0 L446.0 286.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><text x=\"352.0\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the broker holds the message</text></svg>", "caption": "The four styles of Hohpe and Woolf, each with one of Serra Alta's integrations. Only the API needs both sides up at the same moment."}
```

The wrong idea to drop first is that these are generations, file being old and event being modern,
and that a good architecture has moved everything to the newest one. **Each style is the right answer
to some integration and the wrong answer to others**, and Serra Alta's map has all four for reasons
somebody once had. The bank does not offer to receive farm payments as events. A bakery waiting at
checkout cannot be told the stock level tomorrow morning in a file.

## One axis: what each side has to know about the other

The four styles differ in many details, but one question orders them: **how much does each side have
to know about the other, and when?** That knowledge is *coupling*, and in integration it comes in
three kinds that are worth keeping apart.

**Coupling in format.** What does the receiver have to understand about the sender's data? With a
file, it must know the layout: which columns hold the litres, what the header looks like. With a
shared database it must know the tables, and not only the columns it reads but what the sender means
by them: that status `E` means an error, that a row with a null delivery date has not shipped. That
is the deepest format coupling of the four, because the sender's internal model *is* the interface.
With an API or an event, the receiver knows a contract the sender chose to publish, which can stay
still while the sender's internals change.

**Coupling in time.** Do both have to be running at the same moment? With an API, yes: the caller
waits and the callee must answer now. With a file, no: Coleta writes at 23:30, SAP loads at 02:00, and
either may be down in between without the other noticing. With messaging, no: the broker keeps the
message until the consumer is back. A shared database needs the database up, but not the other
application.

**Coupling in location.** Does the sender know where the receiver is, or even that it exists? A
caller has the callee's address in its configuration. A file is written to a directory both sides
agreed on. A publisher knows only the broker and the name of the topic; **it does not know who is
listening, or how many**, and a new listener can be added without the publisher changing at all.

| | format | time | location |
|---|---|---|---|
| file transfer | the layout of the file | none: written now, read later | both know the directory |
| shared database | the other side's tables and what they mean | the database must be up, not the other application | both know the database |
| API | the published contract | both must be up at once | the caller knows the callee's address |
| event | the message's contract | none: the broker holds it | the publisher knows only the broker |

Read down the time column and you have the reason most enterprise integration is not done by API.
**Systems that cannot all be up at once cannot all be called at once**, and in a company with an ERP,
a 1996 system on IBM i, a CRM in somebody else's cloud and two banks, being up at once is something
you arrange rather than assume.

## Style is a property of the row, not of the system

One system usually takes part in several styles at once. SAP, at Serra Alta, receives Coleta's file,
answers the Portal B2B's stock calls through the ESB, has its tables read by two reports nobody
admits to, and puts messages on MQ when a delivery leaves a plant. Asking "how do we integrate with
SAP?" has four answers. Asking "how should the Portal B2B learn SAP's stock?" has one, and that is
the question an architect can decide.

Joana's map counts **41 file transfers, 17 database links, 33 API calls and 19 message flows**. The
ESB carries 70 of them: 31 of the calls, all 19 message flows and 20 of the files, which it picks up
from one directory and drops in another. The other 40 go point to point, and those are where most of
the 38 unanswered rows sit. Lesson 8 explains why a bus was installed to stop exactly that growth;
the last section of this lesson goes through six of the rows and decides which style each should
have.

The next four sections take the styles in turn, from the oldest. **For each one the question is the
same: what does it couple, and how does it fail?** The second half of that question matters more,
because the failure of each style has a typical shape, and knowing the shape is how you know where to
put the alarm.
