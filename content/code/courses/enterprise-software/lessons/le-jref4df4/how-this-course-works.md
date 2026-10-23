---
title: How this course works
version: 1
---

Most courses in this track teach you to build something. This one is about the systems a large
company **bought** rather than built, and about the work of connecting them. **In a company of a few
thousand people, most of the software that runs the business was written by a vendor, configured
by a consultancy and connected by somebody who has since left**, and it cannot be switched off for
an afternoon while you think. The architect's job there is less about drawing a new system than
about changing a running one without stopping it.

The course has two halves, and they are not the same size on purpose.

| lessons | what they are | how they are taught |
|---|---|---|
| 1 | what an ERP is, and why it shapes everything around it | ideas, with one company as the example |
| 2 to 6 | five products: SAP, Microsoft Dynamics, Salesforce, OpenText Documentum, IBM BPM | from the vendors' documentation and from how one company uses them |
| 7 to 15 | process modelling, the service bus, the styles and patterns of integration, queues, contracts and SLAs, retiring a legacy system, migrating its data, and buying versus building | vendor-free, with diagrams, numbers and three short programs |

**The second half is the larger and the more durable one.** The products in lessons 2 to 6 will be
renamed and repriced within a few years; how to move data between two systems that disagree about
what a customer is will not change. The first half is there because you cannot design around a
product you have never had explained to you, and because an architect who joins a large company
meets those names in the first week.

## The products you will not touch

**You will finish this course without having used SAP, Dynamics, Salesforce, Documentum or IBM
BPM**, and that is the design rather than a gap. None of them is sold to a person. A licence is an
enterprise contract, negotiated by a sales team over months and priced for a company, so there is
no bill an individual can pay to get one. Lessons 2 to 6 are taught from the vendors' published
documentation and from how the company in this course uses each product.

Two of the vendors do let anybody look around. Salesforce gives away a free Developer Edition org,
and Microsoft has time-limited trials of Dynamics 365 and a free developer plan for Power Apps. The
lessons name them where they help. **Nothing in the course depends on them**, because a course that
needs one company's free offer stops working the day the offer changes.

If you want to see an ERP from the inside, two open-source ones can be installed on your own
machine: Odoo's Community edition and ERPNext. Neither is the subject of a lesson and neither is
needed, but either will show you a sales order turning into a delivery and an invoice, which is
what lesson 1 describes.

## Nothing to install

**The practice in this course is reading, deciding, drawing and writing.** What you need is four
ordinary tools, each with a free option:

| tool | free options | where the course uses it |
|---|---|---|
| a text editor | the one you have used since the start of the track | your notes in every lesson, the interface contract of lesson 12, the decision record of lesson 15 |
| a diagram tool | diagrams.net, in the browser or as a desktop app, saving to your own disk; Excalidraw; paper and a pencil | maps of systems from this lesson on, BPMN models in lesson 7, migration plans in lessons 13 and 14 |
| a place for decision records | a folder of Markdown files, one per decision, in a git repository if you like | the decisions Joana writes, and yours, from lesson 1 to lesson 15 |
| a spreadsheet | LibreOffice Calc; any other works the same way | availability sums in lesson 12, three options priced over three years in lesson 15 |

**Paper is not the lesser choice for the diagrams.** A tool tempts you to make the drawing tidy;
paper makes you decide what the boxes are, and that decision is the skill.

## Three short programs, and where to run them

Lessons 9, 10 and 14 each show a short Python 3 program: a file with a control total, a message
consumer that ignores duplicates, and a reconciliation of two data sets. **Each program is printed
whole in its lesson, uses only Python's standard library, and needs nothing else.** Reading a
program and the output printed under it is enough to follow the lesson. Running it is optional, and
worth doing, because changing a line and watching what breaks teaches more than the paragraph does.

Any Python from 3.10 on runs them. There are three places to get one:

| | what it is | what it costs your computer |
|---|---|---|
| **your Linux machine** (recommended) | the virtual machine you built in `linux-terminal` lesson 1. Ubuntu Server 24.04 already has `python3` installed | nothing new: it is the machine you already have |
| **installed** | Python from python.org on Windows or macOS, or the `python3` package from your Linux distribution | a little disk, well under a gigabyte |
| **online** | any service that runs Python in a browser tab or on a rented machine | nothing on your computer, and whatever that service decides to charge |

**The recommended one is the machine you already built.** It is where the rest of the track had you
working, and a program that writes files and a small database belongs somewhere you can throw away.

### When it does not work

Three things go wrong, and each has a short answer:

- **`python3: command not found`.** On Windows the command is usually `py` or `python`, from the
  installer at python.org; on a Linux machine, install the `python3` package with the distribution's
  package manager, as `linux-terminal` showed.
- **The version is older than 3.10.** `python3 --version` says which one you have. Older machines
  carry an older Python; install a newer one beside it rather than replacing the system's own.
- **`No module named '_sqlite3'`** in lesson 10. A few minimal builds of Python leave out SQLite.
  The python.org installers and the Ubuntu package include it; a Python compiled by hand may not.

If none of the three fixes it, read the lesson's program and its output and carry on. The program
is there to make the idea concrete, and the idea is in the prose.

## The company you will follow

Every lesson follows one company. **Serra Alta Laticínios is invented**: a dairy in Juiz de Fora,
Minas Gerais, founded in 1968, with about 3,200 employees. It has four plants. Juiz de Fora makes
milk and yoghurt, Barbacena milk powder, Lavras butter and cream, and Alagoa cheese. The cheese plant
came with the purchase of Queijaria Mantiqueira in 2021.

**Serra Alta collects about 2.3 million litres of milk a day from about 1,900 farms**, 365 days a
year, and that fact explains a great deal about its systems. A farm's cooling tank holds two days of
milk at most, so a truck that does not come means milk poured away. Farms are paid on the 10th of
every month, by the litres collected and by the quality measured in the laboratory: fat, protein
and the counts that say how clean and healthy the milk is. Serra Alta sells to supermarket chains,
to distributors and to about 4,000 bakeries and small shops, and every sale needs an NF-e, the
electronic invoice that the state tax authority must authorise before a truck leaves.

Here is what runs it. Each system gets its own lesson or turns up in several.

| system | since | what it does |
|---|---|---|
| SAP ECC 6.0 | 2011 | the ERP: finance, sales, purchasing, stock, production, quality, warehouse. About 520 users |
| SAP BW and BusinessObjects | 2013 | reports, about 900 of them |
| Microsoft Dynamics 365 Business Central | 2019 | Mantiqueira's ERP, kept after the purchase |
| Microsoft 365 and Entra ID | 2017 | email, Teams, documents, and the sign-in everybody uses |
| Salesforce | 2018 | 140 sales representatives for the big customers, and customer service |
| OpenText Documentum | 2010 | quality documents: procedures, laboratory certificates, audit reports |
| IBM BPM | 2014 | three business processes, including the onboarding of a new farm |
| Coleta | 1996 | milk collection and the basis of every farm's payment, on an IBM i (AS/400), written in RPG |
| IBM Integration Bus and IBM MQ | 2015 | the service bus, about 70 integration flows |
| Rota | 2022 | route planning for the milk trucks, built in house |
| Portal B2B | 2023 | the ordering site for bakeries and small shops, built in house |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 410\" role=\"img\" data-fig=\"l01-estate\" aria-label=\"A map of Serra Alta's systems. SAP ECC 6.0 sits in the middle. Above it, four systems connect to it: Salesforce, OpenText Documentum, IBM BPM, and SAP BW with BusinessObjects. To its left, Coleta on an IBM i sends it a file every night; to its right, Business Central at Mantiqueira. Below it runs the service bus, IBM Integration Bus with IBM MQ, which connects SAP to Rota, the Portal B2B and the outside world of banks, the tax authority and customers' EDI. Microsoft 365 and Entra ID, bottom right, give everybody their sign-in.\"><defs><marker id=\"l01-estate-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-estate-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"17.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Salesforce</text><text x=\"95.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sales and service</text><path d=\"M95.0 72.0 L293.8 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"192.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Documentum</text><text x=\"270.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quality documents</text><path d=\"M270.0 72.0 L337.5 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"372.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IBM BPM</text><text x=\"450.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three processes</text><path d=\"M450.0 72.0 L382.5 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"547.0\" y=\"25.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">BW + BusinessObjects</text><text x=\"625.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900 reports</text><path d=\"M625.0 72.0 L426.2 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"146.0\" width=\"200.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"360.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC 6.0</text><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the ERP, since 2011</text><rect x=\"17.0\" y=\"152.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Coleta</text><text x=\"95.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">IBM i, RPG, 1996</text><path d=\"M173.0 175.0 L258.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-amber)\"></path><text x=\"215.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nightly file</text><rect x=\"547.0\" y=\"152.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Business Central</text><text x=\"625.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mantiqueira</text><path d=\"M547.0 175.0 L462.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"246.0\" width=\"420.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">service bus: IBM Integration Bus + IBM MQ, about 70 flows</text><path d=\"M360.0 244.0 L360.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"17.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rota</text><text x=\"95.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">truck routes</text><path d=\"M95.0 325.0 L240.8 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"192.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Portal B2B</text><text x=\"270.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,000 bakeries</text><path d=\"M270.0 325.0 L319.5 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"372.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">banks · SEFAZ · EDI</text><text x=\"450.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outside the company</text><path d=\"M450.0 325.0 L400.5 282.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-estate-es-ah-paper-dim)\" marker-start=\"url(#l01-estate-es-ah-paper-dim)\"></path><rect x=\"547.0\" y=\"327.0\" width=\"156.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></rect><text x=\"625.0\" y=\"342.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft 365 + Entra ID</text><text x=\"625.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">everybody's sign-in</text></svg>", "caption": "Serra Alta's estate as Joana finds it. Everything is drawn around SAP because everything is arranged around it; the amber line is the oldest integration in the company."}
```

## The people

The protagonist is **Joana Brandão**. She spent eight years at a fintech in Belo Horizonte where
every system was built in house, as services, by teams she knew by name. In 2026 Serra Alta hires her
as its first enterprise architect. She knows how to build software well. What she is about to learn
is what it means to change a company whose systems were bought, and the course follows her through
that, including the parts she gets wrong.

| person | role |
|---|---|
| Joana Brandão | enterprise architect, new to Serra Alta |
| Regina Fontes | CIO, who hired her |
| Marcos Teles | finance director; to him, the ERP is the company's books |
| Edson Prado | leads the SAP team, at Serra Alta for fifteen years |
| Rui Andrade | leads integration: the service bus, the queues, the exchanges with customers |
| Talita Gomes | administers Salesforce |
| Felipe Arruda | Mantiqueira's IT, and the owner of Business Central |
| Cláudia Mendes | quality manager |
| Denise Okada | runs the process office |
| Sebastião Lima | wrote most of Coleta, and retires in 2028 |

Everybody in that table is fictional, and so are Serra Alta's numbers. The products, the standards
and the ideas are real, and each is named with its source so you can read the original.

## How a lesson is laid out

Every lesson opens with a short video saying what it is for, follows with reading sections, and
ends with a practice section. **The questions in a lesson carry no mark.** A wrong answer shows you
why it is wrong and you carry on. Many of them ask for a judgement — which integration style fits,
which system should own a field — and for those the course commits to one answer and gives its
reasoning in the option itself. If you still disagree after reading it, the question has done its
job. The course exam at the end is the only place with a mark.

## A habit worth starting now

Keep one text file per lesson. **When the lesson does something at Serra Alta, write down what the
same thing looks like where you work**, or in the last system you worked on. Draw your own company's
version of the map above, even if it has four boxes. Serra Alta is tidy because it was invented for
teaching. Your own estate is not, and the gap between the two is where this course gets tested.
