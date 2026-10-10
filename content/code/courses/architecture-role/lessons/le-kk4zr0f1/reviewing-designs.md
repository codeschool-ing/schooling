---
title: Reviewing a design document
version: 1
---

A design review that starts on page one and comments on whatever it meets is a proofreading pass.
It catches unclear sentences, odd names and the reviewer's own preferences, and it misses what
matters: whether the design solves the problem it was written for, and what it does when something
fails. **Read for the problem first, then the quality attributes, then walk every part asking what
happens when it breaks, and mark each comment as blocking or not.** That order is the whole method.

## Ícaro's first design

Ícaro Nunes is a junior developer on Payments, two years out of university. About one Pix payout in
fifty fails on its first attempt, because the receiving bank is briefly unavailable or the request
times out. A person on the Payments team goes through the list of failures every morning and
retries them by hand, so a driver whose payout failed at 19:00 on a Friday waits until Monday.
Bruno Farias, the tech lead, asked Ícaro to design automatic retries. Ícaro wrote a four-page
document whose core was one paragraph:

> When a payout fails, the payout worker puts it back on the queue with a delay of 5 minutes, then
> 15, then 60. After three failed retries it marks the payout as `failed` and alerts the on-call
> engineer.

Bruno asked Renata to review it. She read it in three passes, not one.

## First pass: the problem and its measure

Before looking at the solution, Renata looked for two things: the problem in one sentence, and the
number that would say whether the design worked. The document had the first ("drivers wait too
long when a payout fails") and not the second. Her first comment asked for it. The answer Ícaro and
Bruno wrote in was Carreto's promise from lesson 4: a driver is paid within 24 hours of a proved
delivery. The same conversation produced two more numbers: 2% of payouts fail on the first attempt,
which is about 160 a day out of roughly 8,000.

**A design with no stated measure cannot be reviewed, only liked or disliked.** Once the 24-hour
promise was in the document, every later comment had something to be tested against. Retries at 5,
15 and 60 minutes finish 80 minutes after the first failure, comfortably inside 24 hours, so the
schedule itself needed no argument at all.

Then the quality attributes, in the form lesson 6 gave them: which one matters most here, and what
would the team give up for it? For payouts the answer came at once. **A driver must never be paid
twice**; a late payment is bad and recoverable, a double one is money that may not come back.
Correctness outranks speed. Ícaro's document did not say so, and it was about to matter.

## Second pass: walk every part and ask how it fails

Lesson 1 said the connectors matter as much as the boxes. A failure walk takes that literally: for
every box and every arrow in the design, ask what happens if it fails, if it is slow, or if it does
its work twice.

Renata drew Ícaro's design as four parts, the payout worker, the queue, the bank's Pix API and the
payouts table in the monolith's database, and walked them one by one.

- **The queue loses a message.** The payout sits in `retrying` for ever. Ícaro's alert fired only
  after three failed retries, so a lost message raised nothing at all.
- **The worker crashes between calling the bank and updating the table.** The payout went out, the
  table still says `pending`, and the next run sends it again.
- **The bank's API times out.** This was the one. A timeout means "I did not hear back", not "it did
  not happen". The bank may have made the transfer and failed only to answer in time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A sequence between three participants: the payout worker, the bank&#x27;s Pix API and the driver&#x27;s account. One, the worker asks the bank to pay payout 7731, R$ 1,850. Two, the bank makes the transfer. Three, the bank&#x27;s answer is lost and the worker sees a timeout. Four, five minutes later the worker asks the bank to pay 7731 again. Five, the bank makes the transfer again and the driver is paid twice. A note: with one idempotency key per payout, step four is answered already paid and no money moves a second time.\"><defs><marker id=\"retrywalk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"16\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Payout worker</text><path d=\"M110 52 L110 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><rect x=\"265\" y=\"16\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Bank&#x27;s Pix API</text><path d=\"M360 52 L360 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><rect x=\"515\" y=\"16\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Driver&#x27;s account</text><path d=\"M610 52 L610 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><path d=\"M112 94 L356 94\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"235\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1  pay payout 7731, R$ 1,850</text><path d=\"M362 132 L606 132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"485\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2  transfer made</text><path d=\"M358 170 L114 170\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"235\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">3  answer lost: a timeout</text><path d=\"M112 216 L356 216\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"235\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4  five minutes on: pay 7731 again</text><path d=\"M362 256 L606 256\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"485\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">5  transfer made again: paid twice</text><rect x=\"40\" y=\"298\" width=\"640\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"315\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">With one idempotency key per payout, step 4 is answered</text><text x=\"360\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">“already paid”, and no money moves a second time.</text></svg>", "caption": "The failure walk on Ícaro's design. A timeout says nothing about whether the transfer happened, so a plain retry can pay a driver twice; an idempotency key per payout turns the repeat into a question the bank can answer."}
```

**A retry after a timeout is the most ordinary way a payment system pays somebody twice.** The
remedy is old and well understood, and the `architecture` course covered it as idempotency in its
lesson 7: send the same idempotency key with every attempt at the same payout, so the bank
recognises a repeat and does not pay it a second time, and ask the bank for the payout's status
before retrying a timeout. Ícaro knew the idea. He had not connected it to his own design, which is
exactly what a failure walk is for.

For a design of this size the walk takes about twenty minutes. It is where an experienced reviewer
adds most, because it draws on having seen things fail, and it is also the easiest part to teach:
the questions are the same every time.

## Third pass: write the comments, and label each one

Renata wrote seven comments, and each began with a label saying what kind of comment it was. Some
teams take their labels from a published convention called Conventional Comments; others invent
their own. These are the four Carreto settled on.

| label | what it means | must the author act? |
|---|---|---|
| **blocking** | the design cannot go ahead as written | yes, before it is accepted |
| **question** | the reviewer does not understand something | answer it; the answer may turn into a blocking comment, or into nothing |
| **suggestion** | an improvement the reviewer would make | the author decides |
| **nit** | a matter of taste or wording | ignore it freely |

Three of hers, as she wrote them:

> **blocking:** a timeout from the bank does not mean the payout failed. As written, a retry after
> a timeout can pay a driver twice. Please send an idempotency key per payout, and check the
> payout's status with the bank before retrying a timeout.
>
> **question:** what happens to a payout whose message is lost from the queue? I cannot see
> anything that would notice it.
>
> **nit:** I would call the state `awaiting_retry` rather than `retrying`, since nothing happens
> while it waits. Your call.

**One blocking comment, one question, and five that asked for nothing.** Without the labels Ícaro
would have faced seven comments of apparently equal weight from the company's architect. A junior
developer in that position tends to do all seven, the nit about a name included, and to read the
whole review as a verdict on himself. With the labels he knew exactly what stood between his design
and its acceptance.

## What makes a review useful to the author

A few habits matter as much as the method.

- **Review the design, not the author.** "This retries a timeout" rather than "you forgot about
  timeouts". The first describes the document; the second describes Ícaro.
- **Keep blocking comments few and real.** Blocking means the design is unsafe or misses its
  measure. "I would have used a different queue" is not blocking unless the queue fails a stated
  requirement.
- **Say what is good, specifically.** Ícaro's state diagram for a payout was clear and complete,
  and Renata said so in one line. That is information too: it tells the author what to keep doing.
- **Do not rewrite the design.** The reviewer finds the problems and explains them. Had Renata
  rewritten the retry section herself, the design would have become hers, and Ícaro would have
  learnt that his drafts get replaced.
- **Talk when the comments pile up.** Past a handful of serious comments, thirty minutes at a
  whiteboard beats a long thread.

Ícaro's second version added the idempotency key, the status check before a retry and a nightly
sweep for payouts left in `retrying` for more than two hours. Renata approved it in one comment.
Lesson 11 of `architect-communication` takes the same habits to code review, where they apply line
by line and every day.
