---
title: One flow, described and then reviewed
version: 1
---

Rui's team built the supermarket order flow in 2016, and it has run every morning since. It carries
about 300 chain orders a day, a fifth of the 1,400 sales orders SAP takes on a weekday. Nobody had
described it in anything but node names until Joana's integration map (lesson 9) needed a line for
it. This section does two things with it: describes it end to end in the vocabulary, and then uses
the vocabulary to review it. **The description takes one paragraph; the review takes one question per
pattern, and two of the answers were defects.**

## The flow, in the book's words

Here is Rui's flow as it runs, for Vale Verde's order of 40 lines for 12 stores.

1. The EDI provider delivers the interchange to an MQ queue, through a *channel adapter* the
   provider supplies.
2. The flow unwraps the EANCOM *envelope* and a *message translator* turns the order into the
   XML order format the bus uses internally.
3. A *content enricher* looks up, for each of the 40 lines, the store's ship-to number and the
   product's material number in SAP.
4. A *splitter* cuts the order into one message per store and plant: 21 messages, each carrying
   the chain's order number as correlation id and 21 as the size of the sequence.
5. A *content-based router* reads the plant. Alagoa goes to Business Central's channel, the three
   other plants to SAP's, and anything else to an *invalid message channel*.
6. On SAP's side a *service activator* calls the BAPI that creates the sales order; on Business
   Central's side a translator turns the message into a call to Business Central's API. Both reply.
7. An *aggregator* collects the replies by correlation id and completes when 21 have arrived.
8. A *translator* turns the result into an EANCOM `ORDRSP`, the order response message, and the
   provider delivers it to the chain.

A *wire tap* on the first channel copies every incoming order to a message store.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-order-flow\" aria-label=\"The supermarket order flow as Rui built it, drawn in the notation. Top row, left to right: the EDI provider; a translator from EANCOM to the XML order the bus uses; a content enricher that calls SAP once per order line, marked as finding 1; a splitter; a content-based router by plant, with a default exit to an invalid message channel. From the router, Alagoa orders go to Business Central and the rest to SAP. Bottom row, right to left: the replies reach an aggregator that completes only by count, with no timeout, marked as finding 2; a translator from the XML confirmation to an EANCOM ORDRSP; and the EDI provider again. A wire tap on the first channel copies every incoming order to a message store.\"><defs><marker id=\"l11-order-flow-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-order-flow-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-order-flow-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"51.0\" width=\"84.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><text x=\"52.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provider</text><path d=\"M94.0 70.0 L136.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"136.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"144.0\" y=\"65.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M157.0 70.0 L167.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"176.0\" cy=\"70.0\" r=\"5.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></circle><text x=\"163.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">translator</text><text x=\"163.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">EANCOM → XML</text><path d=\"M190.0 70.0 L236.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"236.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"243.0\" y=\"66.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M255.0 71.0 L265.0 71.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"268.0\" y=\"66.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><rect x=\"278.0\" y=\"66.0\" width=\"5.0\" height=\"10.0\" rx=\"0\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M275.0 55.0 L275.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"263.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">enricher</text><text x=\"263.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">SAP, per line</text><circle cx=\"263.0\" cy=\"37.0\" r=\"9\" fill=\"var(--amber)\"></circle><text x=\"263.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">1</text><path d=\"M290.0 70.0 L336.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"336.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"343.0\" y=\"61.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M357.0 70.0 L371.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"372.0\" y=\"55.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M357.0 70.0 L371.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"372.0\" y=\"66.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M357.0 70.0 L371.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"372.0\" y=\"77.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">splitter</text><text x=\"363.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">store × plant</text><path d=\"M390.0 70.0 L436.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"436.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M443.0 70.0 L459.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M459.0 70.0 L481.0 59.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M459.0 70.0 L481.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M459.0 70.0 L481.0 81.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"463.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">router</text><text x=\"463.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">by plant</text><path d=\"M490.0 60.0 L566.0 60.0 L566.0 40.0 L588.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><path d=\"M490.0 70.0 L588.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"590.0\" y=\"25.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><rect x=\"590.0\" y=\"89.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><path d=\"M490.0 80.0 L505.0 80.0 L505.0 160.0 L518.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l11-order-flow-es-ah-amber)\"></path><rect x=\"520.0\" y=\"143.0\" width=\"112.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"576.0\" y=\"153.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">invalid message</text><text x=\"576.0\" y=\"166.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">channel</text><text x=\"498.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">default</text><path d=\"M706 104 L714 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M706.0 40.0 L714.0 40.0 L714.0 238.0 L606.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><text x=\"706.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replies</text><rect x=\"550.0\" y=\"219.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"560.0\" y=\"223.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M569.0 227.0 L583.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"560.0\" y=\"234.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M569.0 238.0 L583.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"560.0\" y=\"245.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M569.0 249.0 L583.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"585.0\" y=\"229.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"577.0\" y=\"267.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aggregator</text><text x=\"577.0\" y=\"280.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">count, no timeout</text><circle cx=\"577.0\" cy=\"205.0\" r=\"9\" fill=\"var(--amber)\"></circle><text x=\"577.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">2</text><path d=\"M550.0 238.0 L430.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"376.0\" y=\"219.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"384.0\" y=\"233.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M397.0 238.0 L407.0 238.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"416.0\" cy=\"238.0\" r=\"5.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></circle><text x=\"403.0\" y=\"267.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">translator</text><text x=\"403.0\" y=\"280.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">XML → ORDRSP</text><path d=\"M376.0 238.0 L96.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"10.0\" y=\"219.0\" width=\"84.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52.0\" y=\"231.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><text x=\"52.0\" y=\"244.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provider</text><circle cx=\"108.0\" cy=\"70.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><path d=\"M108.0 74.0 L108.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-phosphor)\"></path><text x=\"102.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">wire tap</text><rect x=\"56.0\" y=\"151.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">message store</text></svg>", "caption": "Rui's flow in the book's notation, with the two findings of Joana's review marked: an enricher that calls SAP once per line before the split, and an aggregator that can only finish by count. The dashed exit is the router's answer to a plant it does not know."}
```

Compare that with the description Rui gave at the start of this lesson: MQInput, Compute,
SAPRequest, a second Compute, AggregateControl, Route, AggregateReply, MQOutput. The node list is how
the flow is built in IIB. In the book's terms the first Compute node is the translator, and it hands
the lines one at a time to the SAPRequest node, which is the enricher's call. The second Compute node
is the splitter, since one ESQL node can send several messages out of one. The Route node is the
router, and the AggregateControl and AggregateReply nodes, with an AggregateRequest node on each
outgoing branch, are the aggregator. The two branches and the final translation into `ORDRSP` are
smaller flows of their own, reached through queues. **Translating node names into patterns is most
of the work of reading an inherited flow**, and it is worth writing the result down beside the flow,
because the next person will need it too.

## Reviewing with the vocabulary

Each pattern comes with the questions that its failure modes raise. Joana went through the flow with
Rui, pattern by pattern, asking them.

| pattern | the question to ask |
|---|---|
| translator | who owns the mapping, and is there a test with a real message for each level of difference? |
| content enricher | what does it call, how many times per message, and what happens when that system is down? |
| splitter | does every part carry the correlation id and the size of the sequence? |
| content-based router | what happens to a message that matches no rule? |
| aggregator | what is the completion condition, and what happens to a reply that arrives late? |
| service activator | what does the transaction cover, and is the receiver idempotent? |
| wire tap and store | can one message be found by the identifier a customer will quote? |

Most of the answers were good. The splitter stamps the sequence size. The SAP side checks for an
existing order before creating one, so a redelivered message does not make a second order. The store
is searchable by the chain's order number. Two answers were not.

### Finding 1: an enricher that calls SAP 40 times per order

The enricher sits before the splitter and works line by line: one call to SAP for each of the 40
lines of Vale Verde's order. At about 300 orders a day and an average of 35 lines, **the flow makes
around 10,500 synchronous calls a day to SAP to look up data that changes a few times a week.**

The position makes it worse than the count. Because enrichment happens before routing, the cheese
lines bound for Business Central are enriched from SAP too, though Business Central uses none of what
the enricher adds. So when SAP is down on Sunday from 01:00 to 05:00, orders that arrive in that
window wait at the enricher, including the parts that SAP never needed to see.

The redesign moves the enricher after the router, onto SAP's branch only, where it works once per
store-and-plant message: 17 lookups for Vale Verde's order rather than 40, and none for the 4 Alagoa
messages. And it puts a cache in front of the lookup, refreshed every hour from SAP's customer and
material masters, so on an ordinary day the flow calls SAP for almost nothing. **An enricher placed
before a router enriches messages for destinations that do not need it**, and that is a question of
order on the diagram that no amount of tuning fixes.

### Finding 2: an aggregator with no timeout

The AggregateControl node has a timeout property, and in Rui's flow it had never been set. The
aggregator could only complete by count.

It had failed once already. One morning in March, the credentials the Business Central adapter uses
had expired, and every cheese message went to the dead letter queue. **The aggregator waited for
replies that were never going to come**, nine chain orders that included cheese got no confirmation
at all, and the first sign of trouble was Vale Verde's buyer phoning at ten o'clock. Rui's team fixed
the credentials and restarted the flow, and nobody went back to ask why one broken branch had stopped
whole orders.

The redesign completes at 21 replies or after 30 minutes. If the timeout fires, the confirmation goes
out with the missing lines marked as not confirmed, and an alert names the order and the branch that
did not answer. The aggregator also keeps the ids of closed orders for a day, so a reply that arrives
after its order was confirmed raises a correction instead of opening a new aggregate.

### The finding that was not one

Joana raised a third point, and it was wrong. The router's default exit to the invalid message channel
had carried three messages in two years, and she read it as dead code worth deleting. Rui pulled up
the three. They were store orders for a cream cheese from a production line opened at Lavras under a
plant code of its own, which had been set up in SAP and not yet added to the router's rules. **Without the default exit, a message no rule matches
has nowhere to go**, and those three orders would have disappeared rather than waiting where somebody
could see them. A route that carries almost nothing is not unused; it is the one that answers the
question in the table above.

## What the vocabulary bought

The review took one afternoon. It did not need IIB expertise beyond Rui's, and it did not need
Joana to read ESQL. **Every finding came from asking a question the pattern's name implies**, and the
two defects had been sitting in plain sight since 2016 because nobody had described the flow in words
that raise those questions.

The same table works on a design before it is built, which is where Joana now uses it. Lesson 12 adds
the other half of a review: the availability each flow promises, and the contract that says what
happens when it does not keep the promise.
