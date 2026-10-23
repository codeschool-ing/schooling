---
title: What a BPM suite is made of
version: 1
---

The usual picture of a business process management tool is a drawing program. Somebody draws boxes
and arrows, presses a button, and the drawing becomes software. The drawing is what a sales
demonstration shows, and it is the smallest part of the product. **A BPM suite is an engine that
keeps track of work lasting days, with a drawing program attached.** The engine is what Serra Alta
depends on every day, and it is the part that is hard to replace.

This lesson is taught from documentation and description, like lessons 2 to 5. IBM sells its
product to companies through a contract, not to a person with a card. If you want to watch the ideas
run, the open-source engines named in the next section, such as Camunda's and Flowable's community
editions, can be downloaded and started on a laptop. Nothing in the lesson needs them.

Serra Alta has run three processes on IBM BPM 8.5 since 2014:

- farm onboarding, from a field technician's first visit to the farm's first collection, about
  30 days and 220 times a year;
- customer credit approval, when a customer asks to pay on terms instead of in advance, about
  4 days and 1,400 times a year;
- supplier registration, from a buyer's request to a vendor record in SAP, about 12 days and
  600 times a year.

Denise Okada's process office owns the three processes as business rules. One developer, Vinícius
Souza, owns them as software. He joined the integration team in 2014 to build them with two
colleagues, and both colleagues left years ago.

## Seven parts sold as one

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l06-suite\" aria-label=\"The parts of a BPM suite, with the name each part has in IBM BPM. On the left, the modeller (Process Designer) where the process is drawn, saving into a repository of versions (Process Center). A version is deployed as a snapshot to the engine in the centre (Process Server), which runs the instances, waits, calls other systems and routes work. Below it, the engine's own database holds the state, the variables and the history of every instance. On the right, the engine hands tasks to people through a task list and forms (Process Portal and Coaches), calls SAP, Salesforce and the ESB through integration services, and is watched through monitoring and administration (Process Admin Console).\"><defs><marker id=\"l06-suite-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l06-suite-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"12.0\" y=\"43.0\" width=\"188.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"106.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">modeller: the process drawn</text><text x=\"106.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Designer</text><rect x=\"12.0\" y=\"148.0\" width=\"188.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"106.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">repository of versions</text><text x=\"106.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Center</text><rect x=\"267.0\" y=\"133.0\" width=\"190.0\" height=\"84.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"362.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">engine: runs instances,</text><text x=\"362.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">waits, calls, routes work</text><text x=\"362.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Server</text><rect x=\"255.0\" y=\"268.0\" width=\"210.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"284.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">its own database: state,</text><text x=\"360.0\" y=\"299.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">variables, history</text><rect x=\"508.0\" y=\"43.0\" width=\"200.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"608.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">task list and forms</text><text x=\"608.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Portal, Coaches</text><rect x=\"508.0\" y=\"148.0\" width=\"200.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"608.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">integration services:</text><text x=\"608.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP, Salesforce, the ESB</text><text x=\"608.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\"></text><rect x=\"508.0\" y=\"265.0\" width=\"200.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"608.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">monitoring and admin</text><text x=\"608.0\" y=\"299.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Process Admin Console</text><text x=\"608.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">people claim and complete tasks</text><path d=\"M608.0 42.0 L608.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path><path d=\"M106.0 97.0 L106.0 146.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\"></path><path d=\"M202.0 175.0 L265.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-phosphor)\"></path><text x=\"232.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deploy</text><text x=\"232.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snapshot</text><path d=\"M440.0 135.0 L506.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path><text x=\"458.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tasks</text><path d=\"M458.0 175.0 L506.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\"></path><text x=\"482.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">calls</text><path d=\"M360.0 217.0 L360.0 266.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path><path d=\"M440.0 215.0 L506.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-suite-es-ah-paper-dim)\" marker-start=\"url(#l06-suite-es-ah-paper-dim)\"></path></svg>", "caption": "A BPM suite is several products sold as one. The engine sits in the middle, and the database under it holds every instance that has ever run."}
```

Take the suite apart and each piece is something a team would otherwise build. The names in IBM's
product are given beside the generic ones, because those are the words in the documentation and in
Serra Alta's runbooks.

| part | what it does | in IBM BPM |
| --- | --- | --- |
| modeller | where analysts and developers draw the process and attach behaviour to each step | Process Designer |
| repository | keeps each process application and its versions; a frozen version is a *snapshot* | Process Center |
| engine | starts instances, moves each from step to step, waits, routes work, records everything | Process Server |
| process variables | the data each instance carries: the customer, the amount, the documents received | declared in the model, stored by the engine |
| task list | the inbox where a person finds the work waiting for them | Process Portal |
| forms | the screen a task opens | Coaches |
| integration services | the steps that call another system | services in the process application |
| monitoring and admin | what is running, where it stopped, and the repair of a broken instance | Process Admin Console |

The drawing uses BPMN, the notation lesson 7 teaches properly. Here it is enough that each box in the
drawing is a step. A step is one of three kinds: one a person does (a task in somebody's
list), one the engine does by calling another system, or one where the engine decides which way to
go.

**The engine is the part to understand, because everything else is a way in or a way out of it.**
When a process starts, the engine creates an *instance*: one credit request, one farm, one supplier.
The instance has a position in the model and a set of variables, and it lives in the engine's
database. Nothing is running while it waits. No thread sits blocked for three days. The engine
writes the state down, and wakes the instance up when something happens to it: a person completes
a task, a call returns, a timer falls due.

That design has a consequence that the rest of this lesson keeps meeting. **Everything an instance
ever did is a row in a database that belongs to the product.** It is how the engine survives a
restart, and it is also the audit trail, the evidence for reports, and the thing you have to carry
with you if you ever leave.

## IBM's line, and why the names keep changing

IBM's product has two ancestors, and the documentation still shows both.

| year | what happened |
| --- | --- |
| 2009 | IBM announces it is buying Lombardi Software, of Austin, Texas, whose product was built for business analysts to draw and run processes quickly |
| 2011 | IBM releases IBM Business Process Manager, which combines Lombardi's product with its own WebSphere Process Server, a runtime built around SOAP services and BPEL |
| 2014 | Serra Alta installs IBM BPM 8.5 |
| 2018 | IBM renames the product IBM Business Automation Workflow |

The two halves come from different traditions. Lombardi's side is the one people meet: a process
drawn in BPMN, human tasks, forms, and a short loop between drawing and running. The Process Server
side came from the world of the service bus and BPEL, which lessons 7 and 8 describe. IBM sold the
product in editions, and the Process Server side was in the larger ones. Serra Alta bought the
smaller one, so its three processes use only the Lombardi side.

The rename matters in a practical way. Serra Alta's staff say "IBM BPM", its runbooks say "IBM BPM",
and the version installed predates the new name. IBM's current documentation is filed under
Business Automation Workflow, so that is the name to search for. **When a product has been renamed,
learn both names, and note which one the documentation for your version uses.** Lesson 5 tells the
same story about Documentum, where it was the owner that changed rather than the name.

## One credit approval, followed through the engine

A distributor in Ubá, Distribuidora Rio Pomba, wants to buy on 28-day terms with a limit of
R$ 240,000. Its sales rep opens the request in Salesforce. Everything after that happens inside the
engine, and the figure draws it against the clock.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l06-credit\" aria-label=\"One credit approval at Serra Alta drawn against time, from day 0 to day 4, in three lanes: the engine, the credit analysts and the CFO. On day 0 at 09:12 a request from Salesforce starts the instance and the engine fetches a bureau score and the open items in SAP in three seconds. The analysts' task then waits unclaimed for a day and six hours; the review takes 25 minutes. The limit asked for is R$ 240,000, above R$ 150,000, so a task goes to the CFO and waits a day and twenty hours; he approves in four minutes. The engine writes the limit into SAP through the ESB and tells the sales rep. The instance lived three days and three hours; people worked on it for under half an hour.\"><defs><marker id=\"l06-credit-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"138.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">engine</text><path d=\"M150.0 70.0 L678.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"138.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">credit analysts</text><path d=\"M322.9 150.0 L678.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"138.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">CFO</text><path d=\"M150.0 230.0 L321.6 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M573.7 230.0 L678.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M150.0 268.0 L678.0 268.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 264.0 L150.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day 0</text><path d=\"M282.0 264.0 L282.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"282.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day 1</text><path d=\"M414.0 264.0 L414.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"414.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day 2</text><path d=\"M546.0 264.0 L546.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"546.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day 3</text><path d=\"M678.0 264.0 L678.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"678.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day 4</text><circle cx=\"150.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"162.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">09:12 request from Salesforce</text><text x=\"162.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bureau score + SAP open items, 3 s</text><rect x=\"150.0\" y=\"140.0\" width=\"165.0\" height=\"20.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"232.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unclaimed: 1 day 6 h</text><rect x=\"315.0\" y=\"136.0\" width=\"6.0\" height=\"28.0\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">review, 25 min</text><path d=\"M321.0 164.0 L324.2 218.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-credit-es-ah-paper-dim)\"></path><text x=\"330.2\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 240,000 &gt; R$ 150,000</text><rect x=\"324.2\" y=\"220.0\" width=\"241.6\" height=\"20.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"445.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unclaimed: 1 day 20 h</text><rect x=\"565.8\" y=\"216.0\" width=\"6.0\" height=\"28.0\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"561.8\" y=\"252.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">approves, 4 min</text><path d=\"M571.8 216.0 L572.4 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-credit-es-ah-paper-dim)\"></path><circle cx=\"572.4\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"562.4\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limit into SAP via the ESB;</text><text x=\"562.4\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rep told. Done: 3 days 3 h</text><text x=\"360.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">people worked on it for under half an hour; the engine kept it for three days</text></svg>", "caption": "One credit approval against the clock. Almost all of its life is waiting in somebody's task list, and keeping track of the waiting is the engine's job."}
```

1. Salesforce calls a flow on the integration bus, and the flow starts an instance of the credit
   approval process. The instance's variables are filled with the customer, the terms and the limit
   asked for.
2. The engine runs two system steps. It fetches a score from a credit bureau and the customer's open
   items from SAP. Both take three seconds.
3. The engine creates a task, "analyse credit request", and puts it in the list of a **group**, the
   three credit analysts in finance, rather than any one of them. It sits there unclaimed for a day
   and six hours. Then one analyst claims it, which takes it out of the other two lists, reviews the
   numbers in a form and approves in 25 minutes.
4. The engine reaches a decision: limits above R$ 150,000 need the CFO. Marcos Teles gets a task in
   his own list. It waits a day and twenty hours, and he approves in four minutes from his phone.
5. The engine calls the bus again, which writes the new limit into SAP's credit management, and the
   rep is told in Salesforce.

The instance lived three days and three hours. People worked on it for under half an hour.
**Almost all of a process's life is waiting, and keeping track of the waiting is what the engine is
for.** Who has the task, since when, what happens if nobody takes it: those questions are the product.

The example also shows why the engine needs a task list instead of a simple notification. An e-mail
saying "please approve" goes to a person and is gone. A task goes to a role, can be claimed and
released, shows how long it has waited, and survives Marcos being on holiday, because finance can
add a deputy to the group. The task list is the place where the process and the organisation chart
meet, and two sections on, this lesson shows what happens when they drift apart.

## What the history is for

When Serra Alta's external auditors sample credit limits, they ask who approved the limit for a
given customer, when, and on what evidence. SAP can say the limit was changed and by which user. That
user is the integration bus's technical account, which approved nothing. **The answer to "who
decided" lives only in the BPM engine's history**: the analyst who claimed the task, the CFO who
approved it, the score that was on the screen when they did.

That is why a process engine is more than plumbing between Salesforce and SAP. It is the system of
record for decisions taken by people. To Marcos, SAP is the books. For credit decisions, the engine is
the book of who said yes.

Two things it is not, because the names invite confusion. It is not a job scheduler: a scheduler
runs a program at 02:00, while an engine keeps a case open for a month and asks people for things.
And it is not a message queue. A queue moves a message from one system to another and forgets it
(lesson 10). An engine remembers every instance until somebody deletes it.
