---
title: Choosing a region
version: 1
---

The habit this section replaces is choosing by price alone, or not choosing at all and keeping
whatever the console showed first. **A region is chosen with five questions, and they are not
equal.** The first two are constraints: a region that fails either is out, whatever it costs. The
other three are trade-offs, weighed against each other among the regions that are left.

1. What does the law say about where the data may be? This is lesson 2's data-residency question,
   and it is answered by the region, because the region is where the data physically sits. If
   personal data must stay in the country, a region outside it is not an option, and neither is a
   replica there.
2. Does the service you need exist there? Every managed service and instance type you plan to
   use, checked in the provider's own table before anything is designed around it. A region without
   a service you cannot do without is out, unless you redesign.
3. Where are the users, and how far is that in milliseconds? Use the rule from two sections back,
   one millisecond of round trip per 100 km, and then think about how many round trips a page makes.
   A back-office report that runs once a night does not care; a checkout page with twenty calls does.
4. What does it cost there? The sheet showed São Paulo at 1.54 to 1.62 times Virginia for the same
   instances, and the next sections show that moving data out of São Paulo costs more as well.
5. Where are your other systems? The database, the partners' APIs, the identity provider, the
   payment gateway. Anything your code talks to many times per request belongs close to it.

## One application, worked through

A clinic network in Brazil wants an appointment system. Patients book from their phones, all over the
country, and the records are health data about Brazilian residents.

**The law comes first.** Suppose the clinic's lawyers conclude the records must stay in Brazil. That
settles the region for the records before a single price is compared: `sa-east-1`, the one region on
the sheet inside the country. Virginia's lower prices are irrelevant to that data, because a region
that fails a constraint is not in the comparison.

**Latency agrees.** The patients are in Brazil, so a server in São Paulo is a short trip for most of
them: a patient in Fortaleza is 23.7 ms from São Paulo at the floor, while a patient in São Paulo would
be 76.6 ms from Virginia.

**Price is the trade-off that is left, and it can still win somewhere.** The system also renders
reports from anonymised statistics once a night: no personal data, no user waiting. That job could
run in `us-east-1` on an `m7i.large` at 0.10080 an hour instead of 0.16065, if the law allows the
anonymised data out and the lawyers agree it is anonymised. It is also exactly the kind of job the
last question warns about: if it reads the records database twenty thousand times a night across a
continent, the round trips and the transfer out of São Paulo may eat the saving. The usual answer is
"run it next to the data", and the checklist is what makes you check rather than assume.

**The service question is the other constraint, and it can overrule the first answer.** If the clinic's design depends on a
managed service that does not exist in `sa-east-1`, the choice is not between regions any more. It is
between redesigning without that service and failing the law, and that is a decision for the people
who answer for the data, not for the person reading price sheets.

## What the checklist does not decide

It does not decide how many regions. Everything above picks one region for one workload; the section
on multiple regions is about paying for a second one so that a disaster in the first does not end the
business. It does not decide how many zones either: inside the chosen region, the answer is at least
two, and the next section says why and what that costs.

And it does not stay decided. Prices move, services arrive in new regions, and `sa-west-1` shows up in
a published file that CLI 2.37.4 does not list. A region chosen for good reasons three years ago deserves
the same five questions again.
