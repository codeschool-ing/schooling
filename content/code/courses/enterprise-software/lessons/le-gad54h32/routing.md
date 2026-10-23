---
title: Routing, and knowing when an answer is complete
version: 1
---

A routing pattern decides where a message goes and leaves the message itself alone. **The sender
writes to one channel and does not know where its messages end up; the router knows.** That is the
whole value of the group, and the opposite habit is common enough to name first: putting the
decision in the sender. Suppose the Portal B2B knew that cheese is sold by Business Central and
everything else by SAP. Then the EDI flow and Salesforce would have to know it too, each learning the
same rule separately, and every change to the rule would be three changes.

## The routing patterns

The book has twelve patterns in this group. Eight of them carry most of the work, and the easiest way
to keep them apart is to count what goes in and what comes out.

| pattern | in | out | decided by |
|---|---|---|---|
| content-based router | one message | the same message, on one of several channels | the message's content |
| message filter | one message | the same message, or nothing | the message's content |
| recipient list | one message | a copy on each of several channels | a list worked out per message |
| splitter | one message | several smaller messages | the structure of the message |
| aggregator | several messages | one message | a correlation id and a completion condition |
| resequencer | several messages, out of order | the same messages, in order | sequence numbers |
| routing slip | one message | the same message, step after step | a route attached to the message |
| process manager | one message | whichever step comes next | state kept for each instance |

A *content-based router* looks inside the message and sends it to exactly one channel. A *message
filter* is the degenerate case with one exit: the message passes, or it is dropped. A *recipient
list* sends a copy to several channels and computes the list for each message, which separates it
from a publish-subscribe channel, where the list is whoever subscribed. The remaining four take more
explaining, and the supermarket order shows why.

## One order, forty lines, twelve stores

Vale Verde, a fictional chain of 30 supermarkets in Rio de Janeiro and the Zona da Mata, orders from
Serra Alta by EDI every morning. On Monday 19 October its order arrives at 05:40 with **40 lines for
12 stores**. Every store wants milk and yoghurt from Juiz de Fora, five also want butter from Lavras,
and four want cheese from Alagoa.

Three facts shape the flow. A delivery goes to one store from one plant, so the order has to be cut
up. The cheese from Alagoa is sold by Mantiqueira's Business Central, not by SAP (lesson 3 explains
why the company kept two ERPs). And Vale Verde expects **one confirmation for the whole order**, not
twenty-one.

So the flow is a splitter, a router and an aggregator:

1. The *splitter* cuts the order into one message per store and plant. Twelve stores ordering from
   Juiz de Fora, five from Lavras and four from Alagoa make **12 + 5 + 4 = 21 messages**. Each one
   carries the chain's order number as its correlation id, its own position in the sequence, and the
   size of the sequence, 21.
2. The *content-based router* reads the plant. The 4 Alagoa messages go to the channel that
   Business Central reads; the other 17 go to SAP's.
3. Each ERP creates an order and sends a reply.
4. The *aggregator* collects the 21 replies, matched by correlation id, and builds one confirmation
   for Vale Verde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l11-split-route-aggregate\" aria-label=\"The Vale Verde order flow from left to right. One EDI order with 40 lines for 12 stores enters a splitter, which produces 21 messages, one per store and plant: 12 for Juiz de Fora, 5 for Lavras and 4 for Alagoa. A content-based router reads the plant and sends the 4 Alagoa messages to Business Central and the other 17 to SAP. Both ERPs reply, and an aggregator matches the 21 replies by the order number. It completes at 21 replies or after 30 minutes, whichever comes first, and sends one confirmation to Vale Verde.\"><defs><marker id=\"l11-split-route-aggregate-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"103.0\" width=\"108.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Vale Verde order</text><text x=\"64.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">40 lines</text><text x=\"64.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">12 stores</text><path d=\"M118.0 130.0 L162.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><rect x=\"165.0\" y=\"111.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"172.0\" y=\"121.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M186.0 130.0 L200.0 119.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"115.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M186.0 130.0 L200.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"126.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M186.0 130.0 L200.0 141.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"137.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"192.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">splitter</text><path d=\"M219.0 130.0 L276.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><text x=\"248.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">21</text><text x=\"248.0\" y=\"102.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">messages</text><text x=\"248.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12 + 5 + 4</text><rect x=\"279.0\" y=\"111.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M286.0 130.0 L302.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130.0 L324.0 119.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130.0 L324.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130.0 L324.0 141.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"306.0\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">router</text><text x=\"306.0\" y=\"176.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">by plant</text><path d=\"M333.0 122.0 L360.0 122.0 L360.0 62.0 L412.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><path d=\"M333.0 138.0 L360.0 138.0 L360.0 198.0 L412.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><text x=\"386.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 Alagoa</text><text x=\"386.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">17 others</text><rect x=\"412.0\" y=\"42.0\" width=\"116.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><text x=\"470.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 orders</text><rect x=\"412.0\" y=\"178.0\" width=\"116.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"191.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><text x=\"470.0\" y=\"204.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17 orders</text><path d=\"M528.0 62.0 L560.0 62.0 L560.0 122.0 L583.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><path d=\"M528.0 198.0 L560.0 198.0 L560.0 138.0 L583.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><text x=\"548.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">replies</text><rect x=\"585.0\" y=\"111.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"595.0\" y=\"115.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M604.0 119.0 L618.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"595.0\" y=\"126.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M604.0 130.0 L618.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"595.0\" y=\"137.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M604.0 141.0 L618.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"620.0\" y=\"121.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"612.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">aggregator</text><path d=\"M639.0 130.0 L668.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><rect x=\"670.0\" y=\"110.0\" width=\"44.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"692.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"612.0\" y=\"229.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">complete at 21 replies</text><text x=\"612.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">or after 30 minutes</text><text x=\"692.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">confirmation</text><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">every message carries the order number as its correlation id, and the splitter writes 21 into each</text></svg>", "caption": "A splitter, a router and an aggregator: the composed message processor. The aggregator can only count to 21 because the splitter told it; the timeout is what saves it when one reply never comes."}
```

The book has a name for this exact chain: the *composed message processor*. A close relative is
*scatter-gather*, which sends the *same* request to several receivers and aggregates their answers;
asking both ERPs whether they can promise stock for Wednesday would be one.

## The hard part: when is an aggregate complete?

A splitter is easy because it knows everything it needs: the message in front of it. An aggregator
is hard because it has to wait for messages that may never come. **Every aggregator has to answer
three questions**, and the book lists them:

- *correlation*: which messages belong together? Here, the ones carrying the same chain order number.
- *completion condition*: when is the set finished?
- *aggregation algorithm*: how are the parts combined? Here, one confirmation line per order line,
  in the chain's own line order.

The first and third are design work. The second is where flows fail, and there are three basic
answers to it.

*By count.* Wait until 21 replies have arrived. That is why the splitter wrote `sequenceSize` into
every part: the aggregator cannot count to a number nobody told it. Counting alone has one failure,
and it is total. If one reply never comes, because Business Central was down when the cheese message
arrived and the message went to a dead letter queue (lesson 10), **the aggregate never completes**.
No confirmation goes to the chain. Nothing raises an error, because nothing has failed yet; the
aggregator is still waiting, and it will wait for ever.

*By timeout.* Send whatever has arrived after 30 minutes. That never hangs, but it makes every order
wait 30 minutes even when all 21 replies were in after 40 seconds, and it sends a partial confirmation
for an order whose last reply was merely slow.

*Both.* Complete at 21 replies or at 30 minutes, whichever comes first. **A count with a timeout is
the default answer, and an aggregator with only a count is a defect waiting for its first lost
message.** When the timeout fires, the aggregate is incomplete, and the flow has to say so: the
confirmation marks the missing lines as not confirmed, and somebody is told. Vale Verde's contract
gives Serra Alta two hours to confirm an order, so 30 minutes leaves time for a person to act on the
gap.

The book lists more strategies than these three: *first best*, which takes the first acceptable
answer and ignores the rest, as you would when asking several carriers for a quote; and completion
on an *external event*, such as the end of the business day. Count, timeout and both cover nearly
everything an ERP flow needs.

### The reply that arrives after the aggregate closed

One more question hides behind the timeout. Business Central comes back at 06:25 and sends the
cheese reply the aggregator gave up on at 06:12. What happens to it?

If the aggregator has forgotten the order, the late reply looks like the first message of a new
aggregate. It starts waiting for 20 siblings that will never come, and then it times out and sends
Vale Verde a second, nearly empty confirmation. **An aggregator has to remember which aggregates it
has closed, for longer than its timeout**, so that a late arrival is recognised and handled: logged,
and used to send a correction, or passed to a person. Apache Camel's aggregator, for instance, has an
option to refuse correlation ids it has already completed, for exactly this case.

## Resequencer, routing slip and process manager

A *resequencer* puts messages back in order. It holds the ones that arrived early until the gap
before them is filled, which needs a sequence number on every message and, again, an answer to what
happens when the gap never fills. A resequencer without a timeout and a bound on its buffer is the
aggregator's defect in another shape. Lesson 10 covers why order is lost in the first place.

A *routing slip* decides the whole route when the message enters, and attaches it to the message.
Each step does its work, reads the next destination off the slip and sends the message on. It suits a
message whose steps are known at the start and differ by type. An NF-e received from a supplier, for
instance, always needs a check of its schema and a check that SEFAZ authorised it, and needs a match
against a quality certificate only when the supplier sells ingredients.

A *process manager* keeps the route in a central component instead, with state for every instance,
and decides the next step from the result of the last one. Farm onboarding, which lesson 7 modelled
in BPMN, is a process manager: whether the next step is a quality visit or a rejection letter depends
on what the first milk sample showed. **When the route depends on intermediate results, a slip cannot
carry it and a process manager is needed.** IBM BPM, where Serra Alta runs that process today, is a
process manager with a modelling tool attached (lesson 6).

The difference matters when reading a flow, because the book's vocabulary makes it visible where the
state lives. A routing slip keeps it in the message. A process manager keeps it in a database
somebody has to run, back up and migrate.
