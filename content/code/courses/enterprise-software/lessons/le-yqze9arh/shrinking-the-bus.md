---
title: Shrinking the bus
version: 1
---

The tempting answer to a bus that grew is a project to replace it: pick a modern integration
platform, move the 70 flows across, switch IBM Integration Bus off. Vendors offer migration tools
that do exactly that. **Moving every flow as it is to a new product gives you the same bus with a
new licence**: the discount still lives in the pipe, the plant decision still lives in the pipe, and
the team that has to change them is still the only one that can. What shrinks a bus is not a new
product but a different answer, flow by flow, to the question *where does this belong?*

## Freeze before you shrink

The first step costs nothing and is the one most often skipped. While the old flows are being
moved out, new ones keep arriving, and every new rule put in the bus is one more to move later.
Joana's first decision record about the bus, accepted by Regina in November 2026, says one thing:
**from that date, no new flow may contain business logic**, by the test in section 05 of this
lesson. A new flow may route, change a format or bridge a protocol. A team that needs a decision
made puts it in its own service, or asks the owner of the decision to put it in theirs.

A freeze needs someone to hold it. Rui reviews every new flow against the record and is allowed to
say no, and Regina agreed in writing that a missed deadline is not a reason to make an exception.

## The inventory

You cannot classify what you have not listed. Joana and Rui spent three weeks on the 70 flows, and
for each one wrote down the same facts:

| what they recorded | where it came from |
|---|---|
| the systems at each end, and the protocol on each side | the flow's input and output nodes |
| traffic over the last 90 days: messages, failures, last message seen | the bus's own flow statistics and MQ's queue statistics |
| what happens inside: routing only, format changes, calls to other systems, decisions | reading the ESQL and the maps, flow by flow |
| who asked for it, and who owns the systems at each end | change history, and asking |

The third row took most of the time, because only reading the code answers it. A flow called
`SF_ACCOUNT_SYNC` sounds like a translation; it turned out to hold the credit block from section 05.

## Four classes

Every flow fell into one of four classes, and each class has its own destination:

| class | what is inside | where it goes | Serra Alta |
|---|---|---|---|
| routing and protocol | takes a message from one place and delivers it to another, perhaps across a protocol: MQ to HTTP, a file to a queue | stays on a small bus, or becomes plain messaging on MQ, which lesson 10 covers | 24 |
| transformation | changes a format: EDI to IDoc, an SAP record to Salesforce's fields | to the endpoint that owns the format it is translating into or out of | 17 |
| orchestration with business logic | calls several systems and decides something: a discount, a plant, a credit block | to the service that owns the decision, or to a process engine when the decision is a process | 18 |
| no traffic | no message in 90 days | switched off | 11 |

**A transformation belongs to the endpoint that owns one of its formats**, usually the one that is
easier to change. When the Portal B2B team maps its own order into what SAP expects, a change to
the portal's order touches one team. Where neither end can change easily — SAP on one side, a
supermarket's EDI on the other — the translation becomes an adapter owned by the team responsible
for that end, deployed with it, as section 06 built for Rota. Lesson 11 discusses the other option,
a shared canonical format, and why it so often turns into a committee.

The orchestrations are the hard part, because each one needs an owner to accept a rule they did not
know they had. The discount moves into SAP's pricing, where the commercial team already changes
prices. The plant decision goes to the logistics planners' side of SAP. The credit block is removed,
because SAP's own credit management already does the job and the flow's copy used a different
limit. Two orchestrations that are genuinely processes — waiting for a lab result, then for a
signature, then for a bank — move to the process engine that runs farm onboarding, the subject of
lessons 6 and 7.

## Dead is not the same as quiet

Eleven flows showed no traffic in 90 days, and the obvious move is to delete them. Rui asked for a full year of statistics first. Two of the eleven had run, each once: a flow that sends every
farm its annual income statement in February, for the farm's tax return, and a flow that sends the
year-end stock count to the auditors in December. **Ninety days of silence proves nothing about a
flow that runs once a year**, and both are needed. They are transformations, and they moved to that
class. That leaves 9 dead flows, 19 transformations, 18 orchestrations and 24 routing flows, still
70 in total.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l08-classes\" aria-label=\"A bar chart of Serra Alta's 70 message flows by class, after a year of traffic was checked. Routing and protocol: 24, which stay on a small bus or become plain MQ. Transformation: 19, which move to the endpoint that owns the format. Orchestration with business logic: 18, which move to the owner of the decision. Dead: 9, switched off. A note says 11 flows had no traffic in 90 days, and 2 of them run once a year and were counted as transformations.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">70 flows on the bus, by class</text><text x=\"20.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">routing and protocol</text><text x=\"20.0\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stays: a small bus, or plain MQ</text><rect x=\"330.0\" y=\"51.0\" width=\"300.0\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">24</text><text x=\"20.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">transformation</text><text x=\"20.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to the endpoint that owns the format</text><rect x=\"330.0\" y=\"101.0\" width=\"237.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"577.5\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">19</text><text x=\"20.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">orchestration with business logic</text><text x=\"20.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to the owner of the decision</text><rect x=\"330.0\" y=\"151.0\" width=\"225.0\" height=\"26.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">18</text><text x=\"20.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dead</text><text x=\"20.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">switched off</text><rect x=\"330.0\" y=\"201.0\" width=\"112.5\" height=\"26.0\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"452.5\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">9</text><path d=\"M330.0 40.0 L330.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">11 flows had no traffic in 90 days; 2 of them run once a year, so 9 are dead</text></svg>", "caption": "The 70 flows after the inventory. The classes, not the product, decide where each flow goes; 46 leave the bus and 24 stay."}
```

The nine are switched off in a way that can be undone. Each one is stopped, not deleted; the owners
of the systems at both ends are told; and the flow stays stopped through one full month-end close,
because some flows only wake up in the week finance closes the month, which lesson 1 described. After that, its
source goes to the archive and it is removed from the bus. Two months after the freeze, the bus
runs 61 flows, and nothing broke.

## The order of work

The classes also give the order:

1. Freeze new logic, so the inventory stops growing.
2. Inventory every flow with a year of traffic, not ninety days.
3. Switch off the dead, carefully, because it is cheap and it shrinks everything after it.
4. Move transformations out as the teams that own each endpoint touch it for other reasons.
5. Move orchestrations out one decision at a time, each with its owner and its own date.
6. Decide what the routing flows become: a small bus, or plain messaging.

Steps 4 and 5 are paced by other work rather than run as a programme. A transformation moves when
the Portal B2B team is already changing its order format, or when Salesforce is being upgraded;
moving it then costs little extra testing. **A bus is shrunk the way a strangler fig replaces its
host, a branch at a time, while everything keeps running**, and lesson 13 develops that pattern for
Coleta itself.

## Measuring progress

Joana tracks two numbers every month and shows them to Regina: flows that still contain business
logic, and change requests waiting for the integration team. The first falls from 18 towards zero.
The second is the one the business feels. When a transformation moves to the portal team, changes to
it no longer wait in Rui's queue, and by the end of 2027 the plan expects the queue to hold fewer
than five requests at any time.

What is left at the end is not nothing. If everything moves as planned, 9 + 19 + 18 = 46 flows leave
the bus, and 24 remain: routing and protocol bridging, the work a bus was always good at. Whether
those 24 stay on IBM Integration Bus, move to a newer version, or become plain MQ is a smaller
decision with no business rules in it, which is exactly what makes it easy. **The aim was never to
have no bus. It was a bus that nobody has to wait for.**
