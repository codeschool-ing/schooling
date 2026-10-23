---
title: Why companies bought a bus
version: 1
---

The story most engineers tell about the enterprise service bus is short: a big product, sold to big
companies, which turned every integration into a ticket for one overworked team. Joana told it
herself at the fintech, where nobody had a bus and nobody missed one. It is half right. The bus answered a real problem: the number of possible connections grows with the
square of the number of systems. **Most of the trouble it brought came from what people later put
inside it, not from the idea of a hub.** She needs both halves before she touches any of Rui Andrade's 70 flows,
because the people who bought it in 2015 were not foolish, and the reasons they had are still true.

## The arithmetic of point to point

Connect systems directly, each pair that needs to talk with its own interface, and the number of
possible connections between *n* systems is *n*(*n* − 1)/2. Each system can talk to *n* − 1
others, and dividing by two stops a pair being counted twice, once from each end.

| systems | possible point-to-point connections |
|---|---|
| 4 | 6 |
| 7 | 21 |
| 12 | 66 |
| 15 | 105 |
| 20 | 190 |

Twelve is not a number picked for the table. Serra Alta's bus has twelve systems around it today: SAP ECC,
BW with BusinessObjects, Business Central, Microsoft 365, Salesforce, Documentum, IBM BPM, Coleta,
Rota, the Portal B2B, the banks' files and the EDI provider. That gives 12 × 11 / 2 = 66. **Sixty-six is a ceiling, not a count.** Rota has nothing to say to Documentum,
and not every pair talks. But the ceiling is what grows: three more systems take it to 105, which
is 39 more possible interfaces for three new names on the diagram.

What hurts is not the lines. It is what each line carries. A direct interface is a small private
agreement between two systems: a file layout, a field mapping, a schedule, a habit about retries, a
password somebody set in 2012. **Point-to-point integration does not fail all at once; it fails as a
growing pile of agreements that nobody can list.**

Serra Alta learnt that before the bus. In 2014 it had seven systems and 17 direct interfaces
between them, each written by whoever needed it at the time, in whatever the writer knew: ABAP
programs reading files, a Java job polling a table, a script copying a spreadsheet to a shared
folder. When the SAP team changed the material codes for milk powder that year, five of the 17
broke. Three were found the next morning. Two were found by a customer, whose orders had been
arriving with the wrong product for a week.

## The hub promise

The answer the market offered was a hub. Instead of connecting every pair, connect every system
once, to something in the middle, and let the middle do the work: *n* connections instead of up to
*n*(*n* − 1)/2. For Serra Alta's twelve, that is 12 instead of 66.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l08-hub\" aria-label=\"Two panels with the same twelve systems on a ring: SAP ECC, BW/BO, Dynamics BC, M365, Salesforce, Documentum, IBM BPM, Coleta, Rota, Portal B2B, the banks and EDI. On the left, point to point, every pair is joined by a line: 66 lines, the most twelve systems can need. On the right, each system has one line to an ESB in the middle: 12 lines. A note under both says the mappings and rules the 66 lines would carry now sit inside the hub.\"><path d=\"M185.0 72.0 L235.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L271.6 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L285.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L271.6 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L285.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L285.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 222.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 222.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 222.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M85.0 172.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M85.0 172.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 122.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M535.0 157.0 L535.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M543.7 157.0 L585.0 85.4\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M561.0 157.0 L621.6 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M565.0 172.0 L635.0 172.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M561.0 187.0 L621.6 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M543.7 187.0 L585.0 258.6\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M535.0 187.0 L535.0 272.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M526.3 187.0 L485.0 258.6\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M509.0 187.0 L448.4 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M505.0 172.0 L435.0 172.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M509.0 157.0 L448.4 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M526.3 157.0 L485.0 85.4\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"505.0\" y=\"157.0\" width=\"60.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ESB</text><circle cx=\"185.0\" cy=\"72.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"185.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP ECC</text><circle cx=\"235.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"245.0\" y=\"78.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">BW/BO</text><circle cx=\"271.6\" cy=\"122.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"281.6\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Dynamics BC</text><circle cx=\"285.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"295.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">M365</text><circle cx=\"271.6\" cy=\"222.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"281.6\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><circle cx=\"235.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"245.0\" y=\"265.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Documentum</text><circle cx=\"185.0\" cy=\"272.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"185.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IBM BPM</text><circle cx=\"135.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"125.0\" y=\"265.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta</text><circle cx=\"98.4\" cy=\"222.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"88.4\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Rota</text><circle cx=\"85.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"75.0\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><circle cx=\"98.4\" cy=\"122.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"88.4\" y=\"118.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Banks</text><circle cx=\"135.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"125.0\" y=\"78.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><circle cx=\"535.0\" cy=\"72.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"535.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP ECC</text><circle cx=\"585.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"595.0\" y=\"78.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">BW/BO</text><circle cx=\"621.6\" cy=\"122.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"631.6\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Dynamics BC</text><circle cx=\"635.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"645.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">M365</text><circle cx=\"621.6\" cy=\"222.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"631.6\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><circle cx=\"585.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"595.0\" y=\"265.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Documentum</text><circle cx=\"535.0\" cy=\"272.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"535.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IBM BPM</text><circle cx=\"485.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"475.0\" y=\"265.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta</text><circle cx=\"448.4\" cy=\"222.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"438.4\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Rota</text><circle cx=\"435.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"425.0\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><circle cx=\"448.4\" cy=\"122.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"438.4\" y=\"118.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Banks</text><circle cx=\"485.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"475.0\" y=\"78.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><text x=\"185.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">point to point: up to 66 connections</text><text x=\"535.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one hub: 12 connections</text><path d=\"M360.0 40.0 L360.0 296.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">the hub holds every mapping and rule the 66 lines would have carried</text></svg>", "caption": "Twelve systems, the ceiling of n(n − 1)/2 = 66 direct connections against twelve to a hub. The count of lines falls; the count of agreements does not."}
```

The idea is older than the name. In the 1990s the products were called message brokers or EAI
(enterprise application integration) hubs. Around 2002, as web services and service-oriented
architecture arrived, the next generation started being called an enterprise service bus. The
term is usually credited to analysts at Gartner, and David Chappell's book *Enterprise Service
Bus* (O'Reilly, 2004) gave it a shape that vendors then built to. The word *bus* was borrowed from
hardware: one shared channel that every component plugs into, instead of a wire between every
pair.

The promise had four parts. Each one names a need that has not gone away, which is why the same
four words come back in every integration product sold since.

| what the bus promised | what it meant for Serra Alta |
|---|---|
| routing | an order from the EDI provider goes to SAP; a quality alert goes to three places; no sender needs to know who receives |
| transformation | a supermarket's EDI order becomes an SAP IDoc, SAP's own format for documents exchanged with other systems |
| protocol mediation | Coleta speaks MQ from an IBM i; a web application speaks HTTP; the bus lets one reach the other without either learning the other's protocol |
| one place to watch | every message passes one engine, so one console shows what flowed, what failed and what is stuck |

The fourth line sold the product to Regina's predecessor. Before the bus, finding out whether an
order had reached SAP meant asking three people, each of whom knew one of the 17 interfaces. After
it, Rui could open a console and search for the order number.

## The products

Five product lines are the ones you will meet in a company of Serra Alta's age. They differ in
detail and share the shape: a runtime that executes **flows** (a chain of steps a message passes
through), a graphical tool to draw them, a library of connectors for protocols and packaged
applications, and usually a message broker underneath.

| product | where it came from |
|---|---|
| IBM Integration Bus, now App Connect Enterprise | IBM's broker line, earlier called WebSphere Message Broker; almost always installed beside IBM MQ |
| Oracle Service Bus | came to Oracle with BEA Systems, where it was AquaLogic Service Bus |
| TIBCO BusinessWorks | TIBCO's integration product, usually beside TIBCO's own messaging |
| Mule | MuleSoft's, with an open-source core; Salesforce bought MuleSoft in 2018 |
| Microsoft BizTalk Server | Microsoft's integration server, first released in 2000 |

Serra Alta's is the first line. IBM Integration Bus 10 runs Rui's 70 message flows. Each flow is a chain of nodes: an input node that takes a message off an MQ queue or an HTTP request, compute
nodes written in ESQL (the product's own SQL-like language), mapping nodes drawn in a graphical editor, and an output node. **IBM MQ underneath does the part a bus is least often given credit
for: it holds a message safely until the other side is ready to take it.** Lesson 10 is about that
part, and it is the part worth keeping whatever happens to the rest.

Not everything went through it. Coleta's nightly file to SAP is older than the bus and was never
moved, and lesson 9 explains why it may be right where it is.

## What the hub did not remove

The figure above reads like a clean win, 66 against 12. Look at what moved instead of what
vanished. Every mapping, every route, every rule about which system hears about which event still
exists; there are now 12 connections to the bus and, inside it, every relationship the 66 lines
would have carried. **A hub reduces the number of connections; it does not reduce the number of
agreements.** It puts them in one place, under one team.

That is a real gain when the team that owns the place is good at it, and Rui's is. The agreements
are listed, versioned and watched, which they never were in 2014. It becomes a cost when the place
fills with agreements that belong to somebody else, and when every change to any of them has to be
made by the same four people. Section 05 of this lesson is that story.

Two more costs came with the hub. Everything passes one engine, so when the engine stops, every
integration stops with it; lesson 12 does the arithmetic of what that means for availability. And a
bus is a product with a licence, a version and a support calendar. IBM Integration Bus 10 is several versions behind
App Connect Enterprise, and Rui's team spends part of every year on upgrades that change nothing a
user can see.

None of this makes the 2015 decision wrong. Joana's first note in her notebook, after a week of
reading flows, says so: *the bus fixed the 2014 problem. What I inherited is the problem the fix
made, eleven years on.*
