---
title: Power Platform and the integrations nobody drew
version: 1
---

Rui Andrade's map of Serra Alta's integrations shows about 70 flows on the ESB, the nightly file
from Coleta and the EDI provider. It is accurate, and it is incomplete, because the busiest
integration platform in the company is not on it. **Power Platform is an integration platform that
the company's staff use without IT**, and at Serra Alta it carries more connections into SAP than
some of Rui's own flows.

Power Platform is Microsoft's name for three products and the pieces they share:

- Power Apps builds forms and small applications, which keep their data in Dataverse, in SharePoint
  lists or in a spreadsheet;
- Power Automate builds flows: a trigger, such as a schedule, a new email or a new row, followed by
  steps that read and write other systems. It was called Microsoft Flow until 2019;
- Power BI builds reports and dashboards over data it imports or queries.

What they share is the part an architect should look at. There are hundreds of **connectors**, each
a ready-made client for one service: Outlook, SharePoint, Excel, Salesforce, SQL Server, SAP. And
there is the on-premises data gateway, a small service Microsoft provides that a company installs
inside its own network, so that cloud flows and reports can reach systems that are not on the
internet. Most Microsoft 365 business plans include Power Automate with the standard connectors;
others, the SAP one among them, are premium and licensed separately.

The people who build with these tools are called citizen developers: an analyst in credit, a
planner at a plant, a controller in finance, building what they need without waiting for IT. There
is nothing illegitimate about it. They know their work better than IT does, and they build quickly.

## What Joana found

Joana asked the Microsoft 365 administrators for an inventory. Power Platform's admin centre lists
every environment, app and flow, and Microsoft publishes a free set of governance tools, the Center
of Excellence starter kit, that turns those lists into reports. Two weeks later she had numbers.

| what | how many |
|---|---|
| flows built by staff and switched on | 230 |
| people who own at least one flow | 61 |
| flows that reach SAP | 38, all through one connection, as the SAP user `PA_FINANCEIRO` |
| of those, flows that write to SAP | 7 |
| flows whose only owner has left the company | 14 |
| Power Apps | 19 |
| Power BI reports refreshed through the gateway | about 140, most of them reading SAP BW |

The flow that made the numbers real belongs to Priscila Rocha, a credit analyst. Every weekday at
seven it calls SAP through the connector and reads the receivables more than ten days overdue. It
groups them by sales rep, posts a summary in the credit team's Teams channel and adds a row per
customer to an Excel workbook in SharePoint, which the credit committee reads on Thursdays. It has
run every morning since 2023. **It is an integration in every sense lesson 9 will use**: a
scheduled extraction from the ERP, a transformation and two destinations. It has no owner in IT, no
monitoring and no place on Rui's map.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l03-shadow\" aria-label=\"Serra Alta's integrations in two kinds of line. Solid, the ones on Rui's map: Salesforce, the Portal B2B and the EDI provider connected to the ESB (IIB and MQ, about 70 flows), the ESB connected to SAP ECC, Coleta sending SAP a nightly file, and SAP extracting into SAP BW. Dashed and in amber, the ones the inventory found: 230 staff flows in Power Automate, 38 of them reaching SAP as the single user PA_FINANCEIRO, others writing to Teams, SharePoint and Excel; and about 140 Power BI reports reading SAP BW through the gateway.\"><defs><marker id=\"l03-shadow-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-shadow-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20.0 26.0 L50.0 26.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"58.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on Rui's map</text><path d=\"M20.0 48.0 L50.0 48.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"58.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">found by the inventory</text><rect x=\"220.0\" y=\"20.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Salesforce</text><path d=\"M280.0 52.0 L364.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"360.0\" y=\"20.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M420.0 52.0 L420.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500.0\" y=\"20.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EDI provider</text><path d=\"M560.0 52.0 L476.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"335.0\" y=\"94.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ESB: IIB + MQ, ~70 flows</text><path d=\"M420.0 130.0 L420.0 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"350.0\" y=\"186.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"90.0\" y=\"186.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta</text><path d=\"M210.0 205.0 L348.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-shadow-es-ah-paper-dim)\"></path><text x=\"279.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nightly file</text><rect x=\"575.0\" y=\"186.0\" width=\"110.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP BW</text><path d=\"M490.0 205.0 L573.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-shadow-es-ah-paper-dim)\"></path><rect x=\"90.0\" y=\"308.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"323.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Power Automate</text><text x=\"170.0\" y=\"336.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">230 staff flows</text><rect x=\"335.0\" y=\"308.0\" width=\"170.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"323.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Teams, SharePoint,</text><text x=\"420.0\" y=\"336.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Excel</text><rect x=\"570.0\" y=\"308.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"323.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Power BI</text><text x=\"630.0\" y=\"336.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~140 reports</text><path d=\"M210.0 307.0 L380.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-shadow-es-ah-amber)\"></path><text x=\"205.0\" y=\"262.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">38 flows, one user:</text><text x=\"205.0\" y=\"277.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">PA_FINANCEIRO</text><path d=\"M251.0 330.0 L333.0 330.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-shadow-es-ah-amber)\"></path><path d=\"M630.0 307.0 L630.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-shadow-es-ah-amber)\"></path><text x=\"638.0\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">via the gateway</text></svg>", "caption": "The official map, and what the inventory drew over it. The dashed lines carry company data every day and none of them had an owner in IT."}
```

## The wrong first move

Joana's first draft was a policy: block the SAP connector, and route anything that touches SAP
through the ESB, where it can be seen. It was tidy, and it was what her fintech would have done.

Regina asked one question before signing it: what stops on the morning the policy applies? The
answer was 38 flows. Among them were Priscila's morning list, a flow that sends each plant manager
the previous day's milk intake by 06:30, and the seven that write. One of those updates customer
credit limits from the decisions the credit committee records in its workbook, and nobody in IT
knew it existed. Blocked, it would have frozen every limit where it stood, and orders would have
begun to stop at the credit check with nobody able to say why.

Joana withdrew the draft. **Blocking what people built is not governance; it breaks work you have
not yet understood.** The people whose work broke would have rebuilt it the following week in Excel
macros, which have no inventory at all.

## The tools governance is made of

Power Platform gives its administrators four tools, and an architect's design here is mostly a
decision about how to use them.

The first is environments. An environment is a container for apps, flows, connections and
Dataverse data, with its own list of who may build there. Every tenant has a default environment,
and by default everybody with a licence can build in it, which is where all 230 of Serra Alta's
flows were. Further environments can be created with a restricted list of makers, so that a flow
the business depends on runs somewhere people cannot edit by accident.

The second is data loss prevention policies. A DLP policy sorts connectors into three groups:
Business, Non-business and Blocked. An app or a flow may use connectors from the Business group or
from the Non-business group, but not from both, and may not use a blocked one at all. A policy
applies to chosen environments or to the whole tenant. Put SAP, SharePoint and Salesforce in
Business and a personal Dropbox or Gmail connector in Non-business, and **a flow can no longer copy
receivables out of SAP into somebody's personal storage, without anyone blocking SAP.**

The third is ownership. A flow belongs to the person who made it, and its connections act with the
credentials of whoever created them. Disable that person's account and those connections stop
working, and the flow fails on its next run. Flows can have co-owners, and connections can be
created under accounts that belong to a team rather than to a person. Of the 14 flows whose owner
had left, nine had already stopped without anybody noticing which; five still ran, because their
connections had been made with shared accounts rather than the owner's own.

The fourth is the inventory itself. The admin centre and the starter kit answer what exists and who
owns it. Run every month, the same report shows each new flow that reaches into SAP before anybody
depends on it.

## Three tiers, decided by consequence

What Joana proposed instead, and Regina approved, sorts flows by what happens when they fail rather
than by who wrote them.

| tier | what puts a flow there | what it gets |
|---|---|---|
| personal | it serves its author: their mail, their calendar, their files | the default environment, no review |
| team | a team relies on it, or it reads business data | a co-owner, Business connectors only, an entry in the inventory |
| business-critical | it writes to the ERP, or somebody's work stops when it fails | a managed environment, an owning team, a connection identity of its own, failure alerts that reach Rui's team; or a rebuild as an official integration |

The line that does most of the work is the first condition of the last row. **A flow that writes
into the ERP is an integration, whoever built it**, and it gets what every integration gets: an
owner who is not one person, monitoring and a place on the map. The seven writing flows moved into
a managed environment that quarter. Priscila's flow stayed hers, in the team tier, with her manager
as co-owner.

## One user for 38 flows

The single SAP connection needs its own paragraph, because it is the kind of shortcut that reads as
harmless. Every one of the 38 flows acts in SAP as `PA_FINANCEIRO`. SAP records who created and
changed each document, and for everything those flows did, it records that user. When a credit
limit changed in May, SAP could say it was `PA_FINANCEIRO`; it could not say which of the seven
writing flows did it, or on whose decision. **A shared service account turns an audit trail into a
list of things that happened.**

The password was known to four people, two of whom had since moved departments. The fix is dull and
specific: one SAP user per owning team, read-only for the 31 flows that only read, and the seven
writers moved to identities of their own in the managed environment. How SAP licenses access by
other systems through an account like this is the indirect-access question of lesson 1, and lesson
2 says how SAP prices it now.

## Power BI and the number in the board pack

Power BI is the quietest of the three, because a report writes nowhere. It still depends on a chain:
SAP BW, the gateway, a scheduled refresh, a dataset and a dashboard. In March the gateway's server
was restarted for patches and the gateway service did not start again. For eleven days the finance
dashboard in the board pack showed February's figures. The time of the last refresh was printed in
a corner of the page, and nobody looked at it.

The refresh failures had been emailed all along to the analyst who built the report in 2022, who
had moved to another job inside the company. They now go to Rui's team, and the gateway is on the
list of servers that team monitors.
