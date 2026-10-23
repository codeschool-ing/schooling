---
title: System management, and the farm that was not paid
version: 1
---

The other groups of the book describe how a flow works. The last one describes how you find out
that it has stopped working, and what it did to one particular message. **A flow you cannot observe
is a flow you can only debug by asking people what they remember**, and in a company where farms are
paid by a chain of five systems, that is exactly how most investigations at Serra Alta used to run.

## Thursday 10 September

Farms are paid on the 10th. On Thursday 10 September, at four in the afternoon, the owner of Sítio
Boa Esperança, a farm near Barbacena that has sold milk to Serra Alta for nineteen years, phoned the
farm-relations team: the money had not arrived. The farm had delivered every other day all through
August. Somebody had to find the payment.

Between the milk and the money there are five hops, and each one knows the farm by a different name.

| hop | system | what it knows the farm as |
|---|---|---|
| 1 | Coleta records each collection | producer 0417 |
| 2 | the nightly file becomes goods receipts in SAP (lesson 1) | vendor 300417 |
| 3 | SAP's payment run on the 10th creates a payment document | payment document 1500048213 |
| 4 | an IIB flow takes SAP's CNAB 240 remittance file to the bank | a line in the remittance file |
| 5 | the bank's return file reports what happened to each payment | a line in the return file |

Hops 1 and 2 were quick: Coleta had the litres, and the ABAP program that loads the file keeps a
table from producer code to vendor number. Hop 3 was quick too, because inside SAP the document flow
joins the goods receipts to the payment (lesson 1). Hop 4 was where the trail went cold. The
remittance flow wrote a sequence number of its own into each payment line's reference field, not
SAP's payment document number. So the line for vendor 300417 could only be found by its amount and
bank account. And the bank's return file, which had arrived at 07:10 that morning, referred to the
same sequence number, which matched nothing in SAP.

It took finance and Rui's team until the next afternoon to establish what the return file had said
all along: **the payment was rejected because the account was closed.** The farmer had changed banks
in July and the change had reached Coleta's records but not SAP's vendor master. The money was still
in Serra Alta's account. Nobody had been told, because nothing connected the rejection to a vendor.

## The correlation identifier, end to end

The fix was not a new system. **Each hop already had an identifier; what was missing was one
identifier carried across the hops.** The CNAB 240 layout has a field for the payer's own reference
for each payment, and the bank returns it in the return file. Rui changed the remittance flow to put
SAP's payment document number there. From hop 3 to hop 5 the payment now has one name, and a rejected
line in the return file points straight at a document, which points straight at a vendor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l11-trace\" aria-label=\"Five hops of a farm payment from left to right, each with the identifier it knows the farm by. Coleta: producer 0417. SAP goods receipts: vendor 300417. SAP payment run: payment document 1500048213. IIB remittance flow: the CNAB line, with reference 1500048213. Bank return file: reference 1500048213, rejected, account closed. Hops one and two are joined by a mapping table from producer to vendor; hops three to five share one reference, carried end to end. Under the IIB flow a wire tap copies every message to a message store, searchable by vendor and by reference.\"><defs><marker id=\"l11-trace-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-trace-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"74.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"74.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Coleta</text><text x=\"74.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">producer</text><text x=\"74.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0417</text><path d=\"M140.0 120.0 L152.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"154.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"218.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"218.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SAP receipts</text><text x=\"218.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vendor</text><text x=\"218.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">300417</text><path d=\"M284.0 120.0 L296.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"298.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"362.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"362.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SAP payment run</text><text x=\"362.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">payment doc</text><text x=\"362.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1500048213</text><path d=\"M428.0 120.0 L440.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"442.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"506.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"506.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">IIB remittance</text><text x=\"506.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">CNAB line, ref</text><text x=\"506.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1500048213</text><path d=\"M572.0 120.0 L584.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-paper-dim)\"></path><rect x=\"586.0\" y=\"80.0\" width=\"128.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"650.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bank return</text><text x=\"650.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ref</text><text x=\"650.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1500048213</text><text x=\"650.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rejected: account closed</text><path d=\"M14 70 L14 62 L278 62 L278 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"146.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">joined by a mapping table</text><path d=\"M302 70 L302 62 L710 62 L710 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"506.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one reference, carried end to end</text><circle cx=\"506.0\" cy=\"160.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><path d=\"M506.0 164.0 L506.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-trace-es-ah-phosphor)\"></path><text x=\"498.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">wire tap</text><rect x=\"406.0\" y=\"232.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"245.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">message store</text><text x=\"506.0\" y=\"258.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">search by vendor or by ref</text></svg>", "caption": "One farm, five hops, three identifiers. Where one reference is carried from the payment run to the bank and back, the trace is a search; where it is not, it is a join somebody has to do by hand."}
```

That is the correlation identifier from this lesson's section on the pattern language, stretched over a whole
business transaction. **The rule is to pick the identifier at the first hop where it exists, and
carry it unchanged to the last**, not to let each hop invent its own and keep a table of how they
map. Hops 1 and 2 still join by a mapping table, because Coleta predates SAP at Serra Alta and its
producer codes are what farmers know. Lesson 13, which plans Coleta's replacement, returns to that.

## Wire tap, message store and message history

The second change made the IIB flow observable. Three patterns did it.

A *wire tap* copies every message on a channel to a second channel, without changing what the main
flow receives. The book describes it as a simple recipient list with two destinations, one of which
is the flow's own next step. The second destination here feeds a store.

A *message store* keeps a record of the messages that passed, in one place, searchable by the
fields people actually ask about. For the remittance flow those are the vendor number, the payment
document number, the amount and the time. When the next farm phones, the question *did the bank get
this payment?* is a search rather than a project.

*Message history* is a list carried inside the message itself, to which each component appends its
name and a timestamp as the message passes. Where a message store answers *what passed through
here?*, history answers *where has this message been?* without asking each hop separately. IIB flows
can stamp it into a message property at each node that matters.

Two cautions come with a store. **A copy of every message is a copy of every piece of personal data
in it**: the remittance carries farmers' bank accounts and tax numbers, so the store needs access
control and a retention period, decided before it fills up rather than after. And a wire tap must not
be able to stop the flow it watches. If writing to the store fails, the payment must still reach the
bank, which means the tap writes to a queue and something else fills the store.

## The rest of the group

The remaining patterns are about operating a flow rather than following one message.

| pattern | what it does | at Serra Alta |
|---|---|---|
| control bus | administers the components through a channel of their own: start, stop, configure, report | Rui's team stops and starts flows and reads their statistics through IIB's administration interface |
| detour | sends messages through extra steps, switched on and off from the control bus | during a price-list change, orders take a detour through a validation step that checks every price |
| test message | injects a known message to check that a flow works end to end | a synthetic order for a test store, every morning at 05:00, before the chains' real orders arrive |
| channel purger | removes messages from a channel | clears a test queue between runs; never used on a production queue without a copy taken first |

The book imagined the *control bus* as messages on a channel of its own. IIB does the same job
through its web interface and its commands, and the pattern still names what to look for: one place
where every component can be told to stop and asked how it is doing.

A *test message* needs one property above all: **every system downstream has to recognise it as a
test.** Serra Alta's synthetic order names a store that exists only in a test customer group, and the SAP
branch replies to it without creating an order. If any system along the path did not know the store, the test
order would become a real one, and a real sales order at Serra Alta ends in an NF-e, a tax document
the state authority has registered.

A *channel purger* is the most dangerous pattern in the book to use in production, because purging a
queue deletes whatever is on it, and on a production queue those are orders, payments or farm
collections. Messages that cannot be processed belong on a dead letter channel, where somebody can see
them (lesson 10), not in a purge.

## What the Barbacena farm changed

After September the farm-payment trail has one reference from the payment run to the bank and back,
a message store on the remittance flow, and an alert when a return file rejects any payment. The next
rejected payment, in October, was found by the alert at 07:15 on the morning the return file arrived,
eight hours before anybody could have phoned. **The patterns in this group are cheap to add while a
flow is being built and expensive to add during an incident.** That is the argument for drawing them
in the design, beside the routers and translators, rather than leaving them for operations to bolt on.
