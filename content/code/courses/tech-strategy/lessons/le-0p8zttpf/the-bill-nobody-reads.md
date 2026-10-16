---
title: The bill nobody reads
version: 1
---

Coreto's cloud bill arrives on the first working day of every month. It goes to Otávio's team,
somebody checks the total against the contract, and it is paid. **Nobody in engineering opens
it.** Yet every line on it is the result of an engineering decision: a machine sized for a load
test long forgotten, a staging environment that runs all weekend, logs kept for longer than anybody
reads them, a database replica added during an incident and never removed.

The people who spend the money never see the bill, and the people who see the bill cannot change
what is on it. That gap is what FinOps exists to close, and it is a lead's problem before it is
anybody else's.

## The wrong picture

The usual picture of FinOps is a cost-cutting project: finance is alarmed by a number, a tool is
bought, a consultant produces a list, and the bill drops for a quarter before it climbs back. It
fails for the reason the bill was unread in the first place. **The savings were made by people who
do not make the decisions**, so the decisions carry on as before.

The FinOps Foundation, which publishes the practice's framework, describes it instead as a loop of
three phases that an organisation goes round continuously:

| phase | the question | at Coreto |
|---|---|---|
| inform | who is spending what, in units the teams recognise? | each team sees its own share of the bill every month, and the cost of a ticket sold |
| optimise | what can we stop paying for? | the staging environments that run nights and weekends; machines larger than their load |
| operate | how do we keep it from coming back? | staging off by default; a monthly review of the bill with the team leads |

**The order matters.** Optimising before informing produces savings nobody understands, which is
why they decay. Informing without operating produces a report that is read once and then filed. The
three sections that follow take the phases in order: unit cost and showback are the inform phase,
and the usual savings are the other two.

## Why the bill is unreadable

A cloud bill is organised the way the provider sells, not the way the company works. Coreto's runs
to thousands of lines, named by product and region and resource identifier: compute hours in one
zone, storage requests in another, data leaving the network, a managed database by instance class.
None of those lines says "Checkout" or "the on-sale load test". **Reading it requires a
translation from the provider's vocabulary into the company's**, and until somebody does that
translation the bill is a single number that goes up.

Two translations do most of the work. One divides the bill by something the business sells, so the
number can be compared month to month; the next section does that. The other divides it by team, so
each lead sees the part their decisions made; the section after does that.

## What a lead does about it

A lead does not need a FinOps team to start. Coreto has none, and Davi's first step was a meeting:
he asked Otávio for read access to the bill and Rafaela Nunes, who leads Platform, for an hour to
read it with him. The aim of the first month is modest — **put each team's share of the bill in
front of the team** — and it is the step that every later saving depends on.

The other half of the job is the one lesson 11 set up. A saving costs engineering time, and that
time is priced at R$ 150 an hour like any other. A lead who knows both numbers can tell a saving
worth a sprint from one that costs more to find than it returns.

**One warning about what ages.** Providers change how they charge every few years: the names of
their discount schemes, what is billed by the second or by the hour, which services are priced per
request. The specifics in this lesson are written to survive that, and where they mention a pricing
mechanism they describe it generically. What does not age is the questions underneath: what one unit
of the business costs to serve, who spent the money, and whether anybody uses what it paid for.
Check your own provider's current terms before acting on any mechanism named here.
