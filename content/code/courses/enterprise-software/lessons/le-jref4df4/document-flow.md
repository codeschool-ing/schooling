---
title: A sale leaves a trail of documents
version: 1
---

Developers new to an ERP tend to imagine its data as rows that get updated: an order with a status
column that moves from *open* to *shipped* to *invoiced*. **An ERP records a business process as a
chain of documents, each created by one step and pointing at the one before it, and a posted
document is not edited afterwards.** If you understand the chain, you understand where another
system may join it, and that is most of what designing an integration with an ERP comes down to.

## Order to cash

Follow one sale. On Monday, a supermarket chain in Rio de Janeiro orders 600 cases of whole UHT milk
for its distribution centre. Here is what Serra Alta's SAP creates, in order:

1. **The sales order.** Customer, delivery address, material, quantity, price, the date promised.
   Nothing has moved yet and nothing is owed. SAP checks the customer's credit limit here, and
   checks whether 600 cases can be promised for Wednesday.
2. **The outbound delivery.** Created on Tuesday from the order, when the warehouse is told to
   prepare it. It records which plant ships it and when.
3. **The goods issue.** Posted when the truck is loaded. This is the first step that changes the
   books: stock in the Juiz de Fora cold store falls by 600 cases, and the cost of those cases moves
   from the inventory account to the cost of goods sold.
4. **The billing document.** The invoice, created from the delivery. From it, an NF-e is generated
   and sent to the state tax authority, which must authorise it before the truck may leave the plant.
5. **The accounting document.** Posted with the invoice: the customer now owes Serra Alta the amount,
   as an open item in its account receivable.
6. **The incoming payment.** Thirty days later the money arrives in the bank, the bank's file is
   read (lesson 9 has the format), and the payment clears the open item.

Six documents, each with its own number, each pointing at its predecessor. SAP calls the chain the
**document flow**, and any user can open the order and walk forward to the payment, or open the
payment and walk back to the order.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l01-order-to-cash\" aria-label=\"Six documents in a row, each created from the one before: sales order, outbound delivery, goods issue, billing document with its NF-e, accounting document, incoming payment. A dashed line above says each document points at the one before it. Below the goods issue: stock falls by 600 cases and the cost moves to cost of goods sold, the first change to the books. Below the accounting document: the customer owes the amount. Below the payment: it clears the open item.\"><defs><marker id=\"l01-order-to-cash-es-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l01-order-to-cash-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"8.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sales</text><text x=\"60.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">order</text><text x=\"60.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Monday</text><path d=\"M113.0 118.0 L127.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"128.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outbound</text><text x=\"180.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">delivery</text><text x=\"180.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Tuesday</text><path d=\"M233.0 118.0 L247.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"248.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goods</text><text x=\"300.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">issue</text><text x=\"300.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wednesday</text><path d=\"M353.0 118.0 L367.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"368.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">billing</text><text x=\"420.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">+ NF-e</text><text x=\"420.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wednesday</text><path d=\"M473.0 118.0 L487.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"488.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">accounting</text><text x=\"540.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">document</text><text x=\"540.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wednesday</text><path d=\"M593.0 118.0 L607.0 118.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-order-to-cash-es-ah-paper)\"></path><rect x=\"608.0\" y=\"92.0\" width=\"104.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"111.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">incoming</text><text x=\"660.0\" y=\"124.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">payment</text><text x=\"660.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 days on</text><path d=\"M660.0 84.0 L660.0 66.0 L60.0 66.0 L60.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l01-order-to-cash-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">each document points at the one before it</text><path d=\"M300.0 170.0 L300.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"300.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stock − 600 cases</text><text x=\"300.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cost of goods sold +</text><path d=\"M540.0 170.0 L540.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"540.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the customer owes</text><text x=\"540.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">an open item</text><path d=\"M660.0 170.0 L660.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"660.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">clears the</text><text x=\"660.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">open item</text><text x=\"250.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the three highlighted steps change the books</text></svg>", "caption": "Order to cash for 600 cases of UHT milk. Nothing is updated in place: each step adds a document, and an integration joins the chain at the step it represents."}
```

## The same shape in purchasing

The milk comes in through the mirror image of that chain, called **procure to pay**. The farm is a
supplier; the truck's collection is a goods receipt; the monthly statement of litres and quality is
the supplier's invoice, checked against the receipts; the payment on the 10th clears it. At Serra
Alta the first link of that chain is not in SAP at all. Coleta records each collection and sends the
day's total for each farm to SAP every night, as a file, and an SAP program turns each line into a
goods receipt. Lesson 9 takes that file apart, and lesson 13 is about replacing the system that
writes it.

## Why documents and not updated rows

Three reasons, and each one becomes a rule that a system outside the ERP has to respect.

**An auditor has to be able to follow the money.** A document that could be edited after it was
posted would let anybody change what the books said happened, which is the one thing an accounting
system exists to prevent. So a posted document is final. **A mistake is corrected by a new
document that reverses the old one**, and both stay in the books: the goods issue posted to the
wrong plant is cancelled by a reversal and posted again, and an auditor sees all three.

**Each document is the record of one decision, by one person, at one time.** The order is what the
customer asked for. The delivery is what the warehouse agreed to ship. The invoice is what was
charged. When the customer complains that they ordered 600 cases and were charged for 580, the two
documents say exactly where the difference arose, and the delivery in between says why.

**The period closes.** At the end of each month the finance team closes the accounting period,
after which nothing more may be posted into it. A goods issue that happened on 31 October and is
posted on 3 November lands in November. Lesson 12 is about what that calendar does to every system
that sends data to the ERP.

## Where another system may join the chain

The chain explains the most common mistake in integrating with an ERP. **A system outside it must
enter the chain at the step it actually represents, and let the ERP create everything after.**

The Portal B2B takes orders from bakeries. The right integration creates a **sales order** in SAP,
and SAP then produces the delivery, the goods issue, the invoice and the accounting entry by its own
rules, with credit checks and taxes and stock. The tempting shortcut, because the bakery has already
paid by card, is to create the invoice directly. That invoice would point at no delivery. No stock
would leave the books, the warehouse would never be told, and the month-end stock count would be
short by every bakery order that ever went through the portal, with nothing linking the gap to its
cause.

The same rule holds for reading. **A system that wants to know whether an order has shipped should
ask about the goods issue, not look at a status field on the order.** The order's status is a
summary SAP computes for its own screens; the goods issue is the event.

## Numbers, once, for a sense of scale

At Serra Alta on an ordinary weekday, SAP records about 1,400 sales orders, a similar number of
deliveries and invoices, and about 1,900 goods receipts of milk, one for each farm collected. Every
one of them is a document with a number, a date, a user and a link to its predecessor, and none of
them is ever updated in place. A system that integrates with the ERP is joining that stream, and it
has to produce documents the stream can carry.
