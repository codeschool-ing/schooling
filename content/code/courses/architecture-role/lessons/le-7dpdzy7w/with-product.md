---
title: Working with product: what, why, and what it costs
version: 1
---

The relationship between an architect and a product director goes wrong in two opposite ways. In
one, the architect is the person who says no: every feature meets a list of reasons it cannot be
built properly, product learns to route around the architect, and decisions get made without the
information they needed. In the other, the architect says yes to everything and absorbs the cost
silently, so features ship on time and the structure underneath gets harder to change with each one.
**Product owns what gets built, why, and in what order. The architect owns the structural how, and
the job of making its cost visible before the decision, not after.** Neither decides the trade-off
alone; product decides it with the consequences on the table.

## A feature that looked like a form

In August Helena brought a request from the grain cooperatives. At harvest, a cooperative often has
more grain to move than one truck carries, and today a shipper creates one load per truck by hand,
typing the same origin, destination and cargo two or three times. Helena's request was a field on
the load form: *number of trucks*. On the screen it was one input and a validation rule. The Shipper
team estimated it at a week.

Renata read the request against the structure. In the monolith a load corresponds to exactly one
driver, one CT-e, one payout, one tracking session and one line on the shipper's invoice. That
one-to-one runs through Matching's offers, Pricing's quote, Payments' payouts and Tracking's
sessions. A load with three trucks breaks it in all of them at once. **The cost of the feature was not
in the form; it was in an assumption five teams had built on.**

She did not answer with "no", and she did not answer with a design. She wrote Helena a page with two
options, each with what it costs and what it gives:

| | A: linked loads | B: a shipment with legs |
|---|---|---|
| what it is | the form creates three ordinary loads that share an order reference | a new *shipment* that holds several *legs*, each a truck |
| teams involved | Shipper | Shipper, Matching, Pricing, Payments, Tracking |
| estimate | 3 weeks | 11 weeks |
| the shipper sees | three quotes, three CT-e, three lines on the invoice | one quote and one invoice; still one CT-e per truck, as the law requires |
| what it leaves | reports count three loads where the cooperative sees one order | the base for multi-stop routes, already on the roadmap for 2027 |

The estimate for A is three weeks rather than one because the form was only part of it: the order
reference has to appear on the shipper's screens and in support's tools, or nobody can tell that
three loads belong together.

**Helena chose A, with a condition written into the decision**: if linked loads pass 300 a month, B
goes on the roadmap. That is a good outcome, and not because A was the right answer in general. It is
good because the person who owns the priority chose with the eleven weeks and the reporting problem
in front of her, and because the condition means nobody has to win the argument again later. Renata
recorded it as an ADR (lesson 5), with the trigger in the consequences.

## The structural cost, said in product terms

The page worked because it was written in Helena's units. She does not need to know that a foreign
key runs from payouts to loads. She needs to know that option B takes five teams for eleven weeks,
what else those weeks would have built, and what the cooperative will see on its invoice. **An
architect's input to a product decision is a set of options with time, cost, risk and what each one
leaves behind**, in words the decider uses.

Three habits made this work at Carreto:

- Renata joins discovery, not only planning. By the time a feature reaches quarterly planning,
  its shape is decided and an architect can only price it. Two weeks earlier, while Helena's team is
  still talking to cooperatives, a question about the one-to-one could change the shape.
- Each product brief has a structural paragraph. One question, answered by whoever on the team
  knows best: which assumptions in the system does this feature touch? Most answers are "none". The
  ones that are not are where the architect spends time.
- Options, not verdicts. Renata gives two or three options when she can, including the cheapest
  honest one. A single proposal invites a yes or a no; options invite a decision.

## The architect brings ideas too

Working with product is not only pricing other people's requests. The architect knows what the
structure makes cheap, and some of that is valuable to customers nobody has asked yet.

Tracking already emits a position event for every truck every thirty seconds. Turning those into an
estimated time of arrival for the shipper meant a calculation over events that already exist, and the
Tracking team put it at two weeks. Shippers had been calling support to ask where their truck was;
support logged about 1,400 of those calls a month. Renata took the idea to Helena's discovery
session as a possibility with an estimate and a guess at the support calls it would save, and Helena
put it on the next quarter's plan. **The structure is an asset product can spend, and the architect is
the one who knows the balance.**

The same goes for work with no feature attached. An upgrade of the monolith's framework, the CT-e
service itself, the removal of a service nobody needs: each competes for the same weeks as features.
SAFe calls the structural work that keeps the next features cheap the **architectural runway**; the
name matters less than the practice, which is that it goes on the same roadmap as features, argued in
the same terms, rather than being done in the gaps. `tech-strategy` lesson 18 covers a roadmap with
two authors, and lesson 16 there covers the technical decisions that are product decisions in
disguise.

## Where the line sits

Some things are Helena's and not Renata's, however strong Renata's opinion: which customers matter
most, what goes in the next quarter, whether the cooperatives are worth eleven weeks. Some are
Renata's and not Helena's: how a shipment is modelled, which service holds the CT-e data, whether a new
service is justified. The useful test for a disagreement is to ask **whose consequence it is**. If the
cost lands on customers and revenue, product decides with the architect's information. If it lands on
the structure, the architect decides with product's information, and says so.

What stays shared is the trade-off between them: a date against a structure, a feature against
runway. That conversation is a negotiation, and negotiating deadline, scope and debt is
`architect-communication` lesson 13. Lesson 13 of this course comes back to the trade-off itself,
with a fixed regulatory date in it.
