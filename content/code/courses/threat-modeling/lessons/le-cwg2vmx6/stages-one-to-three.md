---
title: Stages 1 to 3, the business and the system
version: 1
---

The first three stages build the context everything else is judged against. At Vereda they took a
morning, with daniel in the room for the first one.

### Stage 1: define the objectives

**What is the system for, and what would hurt if it stopped doing it?** The output is a short list
of business objectives, the security and compliance requirements that come with them, and a first
statement of impact: what failing each objective costs.

| objective | why it matters | compliance |
|---|---|---|
| patients book and pay online | about 60% of bookings come through the portal; the rest by phone | consumer protection, payment card rules through the gateway |
| clinical data stays private | patients share what they would tell nobody else | the **LGPD**: health data is *sensitive personal data* (art. 5, II and art. 11) |
| reminders reach patients | a missed session is an empty slot nobody pays for | none of its own |
| Vereda meets the LGPD | the ANPD can fine and order a stop to processing | the law itself |

The table is where daniel earns his place. A developer would not have written that 60% of bookings
come through the portal, and that number is what makes T01 and T10 expensive in stage 7.

### Stage 2: define the technical scope

**What exactly is being modelled, and what is it built from?** The components, the infrastructure
they run on, the third parties, and the dependencies that come with each. At Vereda: the portal,
the staff console and the worker, the cloud account they run in, the managed database, the
object storage, the SMS provider and the payment gateway, and the libraries each process imports.
The PDF library the console uses to show exams is on this list, which is how T14 got a name.

Stage 2 also writes down **what is out of scope**: the clinics' own Wi-Fi and laptops, which bruno
looks after separately. Out of scope is a decision, and writing it down stops the model being
blamed later for something it never covered.

### Stage 3: decompose the application

**How does data move, and where does trust change?** This is lesson 2: the DFD at level 1, the
trust boundaries, the actors, and the entry points. PASTA adds a list of **use cases** beside the
drawing, because stage 6 will need them: "a patient books and pays", "a physiotherapist opens an
exam", "the worker sends tomorrow's reminders". Each use case is a path through the DFD, and each
will be read backwards in stage 6 as the route somebody could abuse.

Vereda already had stage 3 done when it started PASTA. That is the common case: a team that has
been drawing DFDs can adopt PASTA by adding stages around the work it already does.
