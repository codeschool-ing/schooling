---
title: Clicks before code
version: 1
---

Salesforce can be changed in two ways. **Declarative** changes are made in the setup screens, by
pointing and filling in forms: a field, a rule, a page layout, an automated process. **Programmatic**
changes are code: Apex on the server, Lightning Web Components in the browser. The platform's own
advice, repeated in its documentation and its training for years, is to reach for the first
before the second. Administrators shorten it to *clicks before code*.

The wrong conclusion to draw is that clicks are free and code is expensive. **Both are
customisation, both are kept forever, and both are debt the day nobody remembers why they exist.**
Clicks are cheaper to make and cheaper to change. They are not cheaper to understand three years
later, and Serra Alta's org is the proof.

## What can be done without code

| declarative | what it does | an example at Serra Alta |
|---|---|---|
| a custom field | adds a column to an object | `SAP_Customer_Number__c` on Account |
| a validation rule | refuses a save when a formula is true, with a message | an Opportunity cannot reach *Closed Won* without a delivery region |
| a page layout | decides which fields a user sees, in what order, and which are read-only | the credit limit shown to reps and not editable |
| Flow | runs logic when a record changes, on a schedule, or as a screen a user steps through | when a Case is marked *recall*, assign it to the quality queue and notify Cláudia Mendes's team |

**Flow is now the declarative automation tool, and the older two are on their way out.** Salesforce
used to offer three: Workflow Rules, Process Builder and Flow. It has retired the first two in favour
of Flow. New ones can no longer be created, support for the existing ones has ended, and Salesforce
ships a *Migrate to Flow* tool that converts many of them. Serra Alta still runs 41 workflow rules
and 23 Process Builder processes, most of them written by the consultancy that set the org up in
2018, and moving them to Flow is Talita's main project for the year. Each conversion is small. The
hard part is finding out what each one was for, and that is the theme of this section.

Code is the other half:

| programmatic | what it is | when it is the right tool |
|---|---|---|
| Apex | a strongly typed language that runs on the platform, under the governor limits of section 02 | logic too complex for Flow, or volumes where Flow's limits bite first |
| an Apex trigger | Apex that runs before or after records of an object are saved | keeping several records consistent inside one transaction |
| Lightning Web Components | JavaScript components for the user interface | a screen the standard pages cannot draw |

Apex comes with a rule of its own. **Salesforce will not deploy Apex to production unless tests
cover at least 75% of the org's Apex code** and every test passes. At a company where nobody writes
tests, that rule is the only reason any exist. Serra Alta has 14 triggers and about 60 Apex classes,
nearly all from the 2018 partner, and their tests were written to reach the percentage rather than to
check anything.

## Customisation debt

Talita ran a report last year that she now shows to every new manager. **The
standard Account object at Serra Alta carries 412 custom fields, and 137 of them, a third, have no
value in any record changed in the last year.** Some were created for a campaign in 2019 that ended.
Some are near-duplicates: `Segment__c`, `Segment_New__c` and `Segmento_2020__c` sit side by side,
because each time somebody needed the segmentation changed it was faster to add a field than to
migrate the old one.

Unused fields look harmless, and deleting them looks like housekeeping. Neither is true:

- Every field is on somebody's screen. A rep scrolling past 400 fields to find the buyer's
  phone number is paying for each of them, every visit.
- The platform has a ceiling. Each object can carry a limited number of custom fields, set by the
  edition, and Serra Alta has spent most of Account's.
- "Where is this used" sees only the platform. Salesforce can tell Talita that a field appears in
  a layout, a report or an Apex class. It cannot tell her that an IIB message flow in Rui's team
  reads it every night and writes it into SAP, because that flow lives outside the org.

The third point is the one an architect owns. A field Salesforce reports as unused may be the one
thing an integration depends on, and deleting it breaks a flow in a different system, at 02:00, in
a team that was not told. **Before Serra Alta deletes a field, Talita asks Rui's team to search the
flow mappings for its API name**, and the answer has stopped two deletions so far.

## Sandboxes: where a change is made before it is real

Nobody at Serra Alta changes production directly any more. A change is made in a **sandbox**, a
copy of the org on the same platform, tested there and then deployed. Salesforce offers four kinds,
and they differ in how much of production they carry:

| sandbox | what it copies | what Serra Alta uses it for |
|---|---|---|
| Developer | the configuration only, no records | Talita and the partner build changes, one each |
| Developer Pro | the configuration, with more room for test records | not used |
| Partial Copy | the configuration and a sample of records, chosen by a template | user acceptance tests with three sales managers |
| Full | the configuration and all the records | integration tests against SAP's quality system, and the release preview |

**The Full sandbox is the only place an integration can be tested with production's volume**, and
volume is what breaks integrations, as section 04 shows. It is also a full copy of customer data, so
the people allowed into it are the people allowed into production. A Full sandbox can be refreshed
from production far less often than a Developer one, so it drifts, and Serra Alta schedules its
refreshes around the release previews.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-sandboxes\" aria-label=\"A change travelling from left to right through four orgs. A Developer sandbox holds the configuration and no records; Talita builds the change there. A Partial Copy holds the configuration and a sample of records; three sales managers test it. A Full sandbox holds the configuration and all the records; the SAP integration is tested there at production volume. Production is where the 140 reps work. Above them, a git repository holds the metadata as files: the change is retrieved from the Developer sandbox into it and deployed from it to each of the other three. A note underneath says that each step to the right carries more of production's data, and is guarded more like it.\"><defs><marker id=\"l04-sandboxes-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-sandboxes-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"150.0\" y=\"20.0\" width=\"420.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">git repository: the org's metadata as files</text><rect x=\"15.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Developer</text><text x=\"95.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">configuration only</text><text x=\"95.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Talita builds</text><path d=\"M177.0 190.0 L186.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Partial Copy</text><text x=\"270.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">configuration + a sample</text><text x=\"270.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">sales managers test</text><path d=\"M352.0 190.0 L361.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><rect x=\"365.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Full</text><text x=\"445.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">configuration + all records</text><text x=\"445.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">SAP integration at volume</text><path d=\"M527.0 190.0 L536.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">production</text><text x=\"620.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the real records</text><text x=\"620.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">140 reps</text><path d=\"M95.0 142.0 L180.0 62.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-phosphor)\"></path><text x=\"126.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">retrieve</text><path d=\"M270.0 62.0 L270.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><path d=\"M445.0 62.0 L445.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><path d=\"M620.0 62.0 L620.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><text x=\"452.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">deploy</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">each step to the right carries more of production's data, and is guarded more like it</text></svg>", "caption": "The path of a change at Serra Alta. Only the Full sandbox has production's volume, which is why the integration is tested there and nowhere else."}
```

## A change is a file

Because everything Talita configures is metadata, every change can be read out of an org as a file
and written into another one. That is what makes sandboxes useful rather than decorative. The field
Serra Alta uses to hold the SAP customer number, retrieved with the Salesforce CLI, is this file,
`force-app/main/default/objects/Account/fields/SAP_Customer_Number__c.field-meta.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>SAP_Customer_Number__c</fullName>
    <caseSensitive>false</caseSensitive>
    <externalId>true</externalId>
    <label>SAP customer number</label>
    <length>10</length>
    <required>false</required>
    <type>Text</type>
    <unique>true</unique>
</CustomField>
```

Three of those lines matter later in this lesson. `length` is 10 because an SAP customer number is
ten characters. `externalId` marks the field as a key that outside systems use to find a record.
`unique` makes the platform refuse a second Account with the same number. Section 05 is about why
each of those three is a decision about who owns the customer.

There are two ways to move changes between orgs. **Change sets** are built in the setup screens of
one org and deployed in another: no files, no history, and a list somebody ticks by hand. The
**Metadata API**, usually driven by the Salesforce CLI, retrieves and deploys the files themselves,
which means they can live in a git repository, be reviewed in a pull request and be deployed by a
pipeline. Serra Alta used change sets until 2025. Talita moved to the CLI and a repository after a
change set carried a new validation rule to production and left out the page layout that showed its
field. For forty minutes every rep was told to fill in a field they could not see, and no
opportunity could be saved.

## How Joana reads this

The architecture question in a Salesforce org is rarely "should this be a click or code". It is
**which customisations would anybody choose again**, and who would know if one of them disappeared.
An org seven years old is a system with seven years of decisions in it, and most of them were made
without a record. Joana asks Talita for what she now asks of every system in the estate: the list of
customisations, each with an owner and a reason, and the ones with neither marked for removal. In
lesson 1's terms every one of the 137 fields is configuration, the cheapest ring there is, and
still a cost that nobody chose to keep paying.
