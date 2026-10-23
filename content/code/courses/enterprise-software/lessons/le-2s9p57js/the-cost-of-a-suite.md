---
title: What a suite costs to own
version: 1
---

Joana's first note about IBM BPM was four lines long. Three processes, a licence renewed every year
for something one developer maintains, and a product team down the corridor that writes Kotlin every
day. Rebuild the three processes as services, she wrote, six weeks of work, and stop paying IBM. It
was the note of somebody who had spent eight years building, and it was wrong in a way worth
studying. **The price of a suite is not the licence. It is everything the company has put inside the
product and would have to carry out of it.**

The trigger was a request from Denise Okada. Her office wanted a fourth process on IBM BPM, the
yearly re-qualification of suppliers, on the argument that the platform was already paid for. Regina
asked Joana for an assessment before anybody said yes. This section follows that assessment, cost by
cost.

## The logic is in the vendor's format

The process diagrams in IBM BPM are drawn in BPMN, which is a standard, so it is tempting to think
the processes are portable. The diagram is the least of it. Behind each box is something only the
product understands: a form built as a Coach, a script attached to a step, an integration service, a
variable definition, a rule about who may claim a task. **Exporting the diagram exports the picture
and leaves behind the behaviour.**

Vinícius produced the inventory that Joana's four lines had skipped:

| what | how many |
| --- | --- |
| process applications | 3 |
| forms (Coaches) | 27 |
| integration services, most of them calling flows on the bus | 14 |
| scripts attached to steps | 41 |
| timers | 6 |
| instances open | 1,986, of which 61 live |
| years of history that auditors rely on | 12 |

Each line is work in a rebuild. The 27 forms are 27 screens to design again, with users who know the
old ones. The 14 integration services each have a counterpart on the bus that lesson 8 inherits, and
some of them encode error handling nobody wrote down. The 41 scripts hold business rules: the
credit threshold of R$ 150,000 is one of them, and so is a rule that a farm with an expired health
certificate cannot reach the contract step.

## The skills are scarce, and one person has them

Serra Alta has one person who can change these processes. Vinícius is good, and he is a single point
of failure in the plainest sense: if he leaves, the company can still run its processes, because the
engine runs them, but it cannot change them. Changes then wait for a consultancy, at a consultancy's
rates and lead times.

Joana searched for people with IBM BPM on their profile within commuting distance of Juiz de Fora and
found two. The skill is not dying everywhere, but **a product's skill pool shrinks in every market
where it stops being installed**, and a company that keeps the product keeps paying for that scarcity
in salary, in contractors, or in changes not made. The cheapest fix in the whole assessment is
also the most urgent: a second developer working beside Vinícius this year, whatever is decided
about the product.

## The licence grows with something

IBM licenses much of its middleware by processor capacity, measured in processor value units or in
virtual processor cores, and some products by authorised user, with a yearly subscription and support
fee on top of the licence itself. Which metric a contract uses decides what makes the bill grow.
**Before signing, find the number in your own business that the licence metric follows**, because
that number is going to change. A per-user metric grows when Denise's office adds the 40 field
technicians as users of a new process; a per-core metric grows when the engine needs more servers.

Serra Alta pays IBM about R$ 310,000 a year in subscription and support for BPM. That is Serra Alta's
figure, from its own invoice, and it says nothing about what IBM charges anybody else. It is the
number Joana's first note wanted to save. It is also the only cost on this page that is printed on an
invoice, which is why it gets attention out of proportion to its size. Lesson 15 puts every cost of a
system on one table, three years out, and shows how the ones that are not invoiced decide most
decisions.

## Upgrades are projects

Serra Alta installed 8.5 in 2014 and has not upgraded since. Every year the gap widened: the product
was renamed, new releases came out, and the operating system, the database and the Java runtime
underneath it aged with it. An upgrade now is not a weekend. It is a project with its own testing of
three processes, 27 forms and 14 integrations, and a plan for the instances running at the time.

Joana does not know what IBM's support position for 8.5 is today, and she does not guess. She asks
the IBM account team in writing for three things: the support status of the version installed, the
supported path to Business Automation Workflow, and what that path costs. **A support date quoted
from memory, or from a blog, is a fact about somebody else's contract.**

## The exit

There are two broad ways out, and neither is free.

**Keep the suite.** Pay the subscription, upgrade to a supported version, train a second developer and
keep the processes where they are. The engine keeps doing the hard part well. The cost is the
licence, the upgrade project and the scarcity of skills, every year.

**Re-implement elsewhere.** Move each process to where it fits best: an open engine in Serra Alta's
own code, a platform the company already has, or a purchased product. Each process then needs its
model rebuilt, its forms rebuilt, its integrations re-pointed, its instances in flight drained or
migrated, and its history exported to somewhere readable. Done properly, Joana's six weeks became an
estimate of seven months for two developers, plus the history.

Neither is the default. The useful move is to stop treating the three processes as one decision. They
differ in how long their instances live, how many systems they touch and how often they change.

## Questions to ask before buying a suite

Most of the cost of a suite is decided before anybody uses it. These are the questions Joana now puts
to any process product, including the ones Serra Alta already owns:

- What does an export of a process contain, and what behaviour stays behind in the product?
- How are running instances handled when a process changes: side by side, migrated, or both?
- Where is the history kept, how long, and can the company report from it without the vendor?
- What is the licence metric, and which number in our business does it follow?
- How many people in our market can change processes in this product, and what do they cost?
- What does an upgrade involve, and how often does the vendor expect one?
- If we left in five years, what would we carry out, and in what format?

None of those is about the modeller, and all of them are about the engine and the contract.

## Joana's assessment

The note Joana sent Regina was not four lines.

> IBM BPM stays for now, and it gets no fourth process. Supplier re-qualification goes into the same
> decision as the other three rather than adding to what we would have to move.
>
> This quarter: a second developer beside Vinícius. Export the history of the 1,925 dead instances,
> reconcile the 315 supplier registrations against SAP, and close them with Denise's and finance's
> sign-off. Deploy a version of farm onboarding without the *Fomento leiteiro* branch. Add a retry
> that knows SAP's Sunday window, and an alert on the age of the oldest task in each group. Start a
> nightly export of the history to the warehouse.
>
> In writing from IBM: the support status of 8.5, the path to Business Automation Workflow, and its
> cost.
>
> Then one process at a time. Credit approval first: its instances last four days, so it drains in a
> week, and it touches only Salesforce and SAP. Farm onboarding last, because Denise and I are
> modelling it again from scratch, and its future is tied to Coleta's.

Lesson 7 is that modelling session. Lessons 13 to 15 are Coleta's future, and they decide farm
onboarding's with it.
