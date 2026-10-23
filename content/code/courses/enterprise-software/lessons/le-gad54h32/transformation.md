---
title: Transformation, and the canonical model that ate a year
version: 1
---

Routing changes where a message goes. **Transformation changes what the message is, and leaves the
destination alone.** Two systems that were never designed to talk to each other disagree about
almost everything a message carries, and most of the code in an integration layer is the code that
reconciles them. Rui estimates that four in five of the ESB's 70 flows are, at heart, translators
with some routing around them.

## The message translator, at four levels

The *message translator* is the root of the group: one message in, the same information out in the
shape the receiver expects. The book points out that two systems can disagree at four levels, and a
translator may have to work at all of them at once. The supermarket order shows each one.

| level | what differs | in the Vale Verde order |
|---|---|---|
| data structures | what the entities are and how they relate | the chain sends one order for 12 stores; SAP wants one sales order per store and plant |
| data types | what a field means and in what unit | the chain orders units; SAP sells most products in cases of 12 |
| data representation | how the data is written down | EANCOM segments in the EDI message; XML inside the bus |
| transport | how the bytes travel | the EDI provider's connection; IBM MQ inside the company |

The lower two levels are where tools help most: a library parses EANCOM, MQ carries bytes. **The
upper two are where the knowledge is, and where translators go wrong without anybody noticing.** A
translator that turns 48 units into 48 cases produces a perfectly valid order for twelve times the
milk.

## Envelope wrapper

Some infrastructure needs data around the message that has nothing to do with the business. An
*envelope wrapper* puts the message inside an envelope that meets those needs, and an unwrapper at
the other end takes it out again, leaving the body untouched. You have seen two. The SOAP envelope of
lesson 8 is one. The EDI interchange is another: in EANCOM, an interchange opens with a `UNB` segment
and closes with `UNZ`, and inside it each message opens with `UNH` and closes with `UNT`. The
interchange carries the sender, the receiver and a control reference; the order lines are inside.

The pattern's lesson is to keep the two apart. Consider a flow that reads business data out of the
envelope, such as deciding the customer from the interchange's sender id. It works until the chain
sends through a second EDI provider, and the sender id changes for a reason that has nothing to do
with the order.

## Content enricher, and the call it hides

A *content enricher* adds data the message lacks, from a source the sender did not use. The chain
identifies each store by its GLN. SAP needs its own customer number for the store, which it calls the
ship-to party, and the delivery window agreed with it. Neither is in the order, so the flow looks them
up in SAP and adds them.

On the diagram an enricher is one more icon on an asynchronous flow. **Underneath, it is a synchronous
call to another system, and the flow inherits that system's availability.** When SAP is down for its
weekly maintenance, every Sunday from 01:00 to 05:00 (lesson 1), the enricher fails, and every order
behind it waits, although the flow was drawn with queues precisely so that nothing would wait for SAP.
The call also costs time on every message, and a flow that handles a few hundred orders a day can
afford that in a way a flow handling a reading from every truck cannot.

There are three ways to defuse it, each with its own price:

- *cache* what the enricher looks up. Serra Alta has about 9,800 customers and 2,600 active materials
  in SAP, and they change a few times a week. A cache refreshed every hour answers nearly every
  lookup and goes stale for at most an hour.
- *replicate* the reference data to the bus side, as a table the flow reads, and accept that it can
  be behind.
- *ask the sender* to include it. Sometimes the cheapest enrichment is a field the sender already had
  and nobody asked for.

## Content filter

A *content filter* is the enricher's opposite: it removes what the receiver does not need. SAP's
customer record carries the credit limit, the payment history and the bank details. When customer
changes are published to the Portal B2B, the portal needs the name, the delivery address and the
price list, and nothing else. **Data that never left SAP is data that
cannot leak from the portal**, and some of Serra Alta's bakeries are sole traders whose record holds a
person's tax number, which makes it personal data under the LGPD.

## Claim check

A *claim check* stores a large payload somewhere both sides can reach, and sends a reference in its
place. The receiver uses the reference to collect the payload when it needs it.

Vale Verde's quality team asks for the certificate of analysis of every batch it receives. The
certificates are PDFs of about 2 MB each, and they live in Documentum (lesson 5). Putting the PDF
inside the shipping notice would copy 2 MB through every hop and into every log a wire tap writes. It
would also sit close to IBM MQ's default maximum message length on a queue, 4 MB, so one large
certificate would make a shipping notice fail. So the message carries the Documentum object id, and
the chain's portal fetches the PDF when somebody opens it.

The pattern has two costs that are easy to skip. **The stored payload has to outlive every message
that refers to it**, so somebody decides when it may be deleted. And the receiver needs access to the
store, which is a second interface to secure. Here both are already paid: Documentum keeps the
certificate under its retention rules whatever the message does, and the claim is a reference to a
record that exists anyway.

## Normalizer

Orders reach Serra Alta in three shapes: EANCOM from the EDI provider, JSON from the Portal B2B, and
orders keyed by the key-account reps in Salesforce. A *normalizer* is a router followed by one
translator per format, so that whatever comes in, one format comes out. The question it raises is
which format that should be, and that is the canonical data model.

## The canonical data model, and Joana's first mistake with it

A *canonical data model* is a format independent of every application: each system translates
into it and out of it, and never directly into another system's format. The argument for it is
arithmetic.

If every one of *n* systems sends to every other, point to point needs a translator for each ordered
pair: **n(n − 1)**. With a canonical model, each system needs one translator into the model and one out
of it: **2n**. Five systems all talking to all need 5 × 4 = 20 translators point to point and 2 × 5 = 10
with a canonical model.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" data-fig=\"l11-translators\" aria-label=\"Two panels with the same five systems: EDI, Portal B2B, Salesforce, SAP and Business Central. Left, point to point: every system is joined to every other, ten lines, and each line needs a translator in each direction, so 5 times 4 is 20 translators. Right, with a canonical model: each system is joined only to a central canonical order, five lines, two translators each, so 2 times 5 is 10 translators.\"><text x=\"180.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">point to point</text><text x=\"540.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">canonical model</text><path d=\"M200.6 61.0 L258.3 102.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M184.9 61.0 L236.3 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M175.1 61.0 L123.7 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M159.4 61.0 L101.7 102.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M274.0 132.9 L246.0 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M258.3 132.9 L139.5 219.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M224.9 117.9 L135.1 117.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M187.1 234.1 L172.9 234.1\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M220.5 219.1 L101.7 132.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M114.0 219.1 L86.0 132.9\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M540.0 142.0 L540.0 59.0\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M582.0 146.4 L604.2 139.2\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M553.1 178.0 L597.3 238.8\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M526.9 178.0 L482.7 238.8\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M498.0 146.4 L475.8 139.2\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"500.0\" y=\"144.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">canonical</text><text x=\"540.0\" y=\"166.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">order</text><rect x=\"128.0\" y=\"33.0\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><rect x=\"226.9\" y=\"104.9\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"278.9\" y=\"117.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><rect x=\"189.1\" y=\"221.1\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"241.1\" y=\"234.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><rect x=\"66.9\" y=\"221.1\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"118.9\" y=\"234.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><rect x=\"29.1\" y=\"104.9\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"81.1\" y=\"117.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><rect x=\"488.0\" y=\"31.0\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><rect x=\"598.3\" y=\"111.2\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"650.3\" y=\"124.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><rect x=\"556.2\" y=\"240.8\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"608.2\" y=\"253.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><rect x=\"419.8\" y=\"240.8\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"471.8\" y=\"253.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><rect x=\"377.7\" y=\"111.2\" width=\"104.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"429.7\" y=\"124.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><path d=\"M360.0 30.0 L360.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"180.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">10 lines × 2 = 20 translators: n(n − 1)</text><text x=\"540.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">5 lines × 2 = 10 translators: 2n</text></svg>", "caption": "Five systems that all talk to all. Point to point needs a translator for every ordered pair; a canonical model needs two per system. The left side grows with the square of n, the right side in a straight line."}
```

The arithmetic has a break-even worth knowing. With three systems both sides come to six. With two,
point to point needs 2 and a canonical model needs 4. **A canonical model starts to save translators
only from the fourth system on**, and it brings costs the count leaves out: a format somebody has to
own, version and defend.

Joana arrived from a fintech where every service spoke one shared set of schemas, and in her second
month she proposed a canonical model for the whole company, starting with *Customer*. Three workshops
later the draft had 87 fields, nearly all optional. Edson explained that in SAP a supermarket chain is
not one customer but a set of partner functions: who orders, which stores receive, who is invoiced,
who pays, and Vale Verde has one of the first and 30 of the second. Talita's Salesforce *Account* is
the commercial relationship, with the rep's notes and the next visit. Felipe's Business Central
invoices cheese from Mantiqueira's own company, with its own customer numbers. The Portal B2B's
customer is a bakery with a login. Lesson 1 met the same question inside the ERP; spread across the
company, it has no answer.

**A company-wide canonical model turns into a committee, and every change in any system waits for
it.** And a model where every field is optional promises nothing, because no system can tell from the
schema whether the record it received is usable. Eric Evans named the reason in *Domain-Driven
Design* (2003): a word like *customer* means different things in different bounded contexts, and the
honest design translates at the boundaries rather than forcing one meaning on all of them.

What survived was smaller. **A canonical model pays when it is scoped to one exchange with several
parties on each side.** Joana dropped *Customer* and kept a canonical *order message*: three senders
(EDI, the Portal B2B, Salesforce) and two receivers (SAP, Business Central), owned and versioned by
Rui's team.

The count for that real graph is not n(n − 1), because not everybody sends orders to everybody. Point
to point needs one translator per sender and receiver pair, 3 × 2 = 6. The canonical model needs one
per system, 3 + 2 = 5, since a sender only translates in and a receiver only translates out. That
saves one translator today. The case for it is the next sender. A marketplace channel the sales
director wants next year costs two new translators point to point and one with the canonical model,
and it is built without touching SAP's or Business Central's side at all.
