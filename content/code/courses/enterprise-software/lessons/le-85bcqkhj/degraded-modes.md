---
title: Degraded modes: working while a dependency is down
version: 1
---

Every system at Serra Alta depends on another one, and every one of those will be down at some
point, on purpose or not. The question an architect owes each dependency is not whether it will
fail but **what this system does while it is failing**. "It shows an error" is an answer, and for a
bakery placing tomorrow's order at 05:30 it is the worst one available.

A **degraded mode** is a way of working with less: fewer features, older data, slower confirmation,
more manual work, but still working. It is designed in advance, it is switched on deliberately, and
it has a way back. The common belief it replaces is that resilience means keeping everything up.
Keeping everything up is the availability arithmetic of the first section, and that arithmetic
says every chain fails a few days a year. A degraded mode is what the business does on those days.

## Five shapes

Most degraded modes are one of a small number of shapes. Serra Alta has all of them, some on
purpose and some by habit.

**Store and forward.** The work is accepted and kept until the other side can take it. Coleta's
nightly file waiting in its directory through SAP's Sunday window is the oldest example. A queue in
front of a system is the same idea with better tools, and lesson 10 is about making it trustworthy.
What it needs is room to store, a promise that nothing stored is lost, and a consumer that can catch
up.

**Serve stale data, with its age.** When the source cannot answer, give the last answer it gave and
say when that was. Since lesson 1, the portal does exactly this on Sunday nights: the bakery sees
the stock figure from before the window, with the time beside it. **The age is what makes stale data
honest.** The same figure without its time is a lie that happens to be mostly right.

**Accept now, confirm later.** The order is taken without the system that would confirm it, and
confirmed or refused when that system returns. It moves a failure from the moment the customer is
waiting to a moment when somebody can deal with it. It also creates a new case the business has to
own: the order accepted on Sunday night that SAP cannot fill on Monday morning. The portal's rule is
that the bakery is told before the delivery trucks are loaded, by message, with the item that could
not be supplied.

**Do it by hand.** A paper form in a drawer is a degraded mode, and often the most reliable one.
When Coleta's machine is unreachable, the reception at each plant records the trucks arriving on a
printed sheet, and somebody keys the sheets in when it returns. It is slow, and it needs people who
know where the drawer is, which means it has to be practised.

**Work offline at the edge.** The handheld in each milk truck records each farm's litres, the tank
temperature and the label on the sample bottle. Much of the route is in valleys with no mobile
signal, so the handheld never needed the network to work. It stores the collections, prints the
farmer a receipt, and sends everything when it next has a signal. It keeps the last seven days, so a
failed upload is repaired by sending again. **A design that assumes the network is absent cannot be
broken by its absence**, and for the trucks it was the only design that ever had a chance.

## A legal degraded mode: NF-e contingency

Some degraded modes are written into law, and the Brazilian electronic invoice is one. A load of
yoghurt cannot leave the plant until its NF-e has been authorised by the state tax authority, and
the authority's service is a dependency like any other: sometimes slow, sometimes unreachable. Since
goods that cannot be invoiced cannot be shipped, an outage at the authority would stop the trucks.

So the NF-e rules define contingency modes for issuing when the normal authorisation is
unavailable. Among them are authorisation by a virtual contingency authority run outside the issuing
state's own (SVC, the *SEFAZ Virtual de Contingência*) and a prior registration of a summary of the
invoice (EPEC) that lets the goods leave while the full invoice is authorised later. The printed
document that travels with the goods says that it was issued in contingency, and the issuer has to
regularise every invoice afterwards.

For the architecture, the details matter less than three facts about them. **The degraded mode is
the issuer's to switch on**, so somebody at Serra Alta has to decide, and has to know they may. The
software that issues invoices must already support it, configured and tested before the day it is
needed. And leaving it creates work: every invoice issued in contingency has to be followed until it
is regular. Joana's registry gives the NF-e flow a named owner for the switch and a runbook for
both directions.

## The runbook

A degraded mode that only exists in an architect's head will be improvised by somebody else, at
night, differently. The runbook for each one has the same steps in the same order:

1. detect that the dependency is down, by an alarm on an objective rather than by a phone call
   from a customer;
2. declare the degraded mode: a named person decides, and the decision is recorded with the
   time;
3. switch: turn on the fallback, whether it is the portal's stored figure, the queue or the
   paper form;
4. tell the people affected: the bakeries, the plants, customer service, whoever answers the
   phone;
5. drain what accumulated, once the dependency is back;
6. reconcile: check that everything done in degraded mode reached its destination exactly once,
   and close the mode.

The fifth step is the one that is forgotten when the mode is designed. **Coming out of a degraded
mode takes time, and the time can be calculated.** Suppose SAP is unavailable for 4 hours on a
weekday evening, while bakeries place about 120 orders an hour through the portal. The portal
accepts them for later confirmation, so 4 × 120 = 480 orders are waiting when SAP returns. The job
that creates them in SAP handles about 360 orders an hour, and new orders keep arriving at 120. The
backlog shrinks by 360 − 120 = 240 an hour, so it takes 480 ÷ 240 = 2 hours to clear. The outage
lasted four hours; the degraded mode lasted six. If the drain rate were only 120 an hour, the backlog
would never shrink, and that is a design defect worth finding on paper rather than at 03:00.

The sixth step is lesson 10's territory: a message delivered twice during the catch-up must not
create two orders, which is what an idempotent consumer is for.

## A degraded mode is tested, or it is a guess

The first time a degraded mode is used should not be the first time it runs. With Rui and the portal
team, Joana turned off the stock service on purpose for twenty minutes on a quiet Tuesday afternoon,
announced in advance, and watched what the bakeries saw. The portal served its stored figure as
designed. The time beside it was three hours off, because it was shown in UTC rather than in Brazil's
time. Nobody had seen it before, because on Sunday nights nobody had looked.

That one test found a defect no review had found, and it cost twenty minutes. **A fallback that has
never been switched on is a hypothesis about how the system behaves**, and it is cheaper to test the
hypothesis on a Tuesday than on the night it is needed.
