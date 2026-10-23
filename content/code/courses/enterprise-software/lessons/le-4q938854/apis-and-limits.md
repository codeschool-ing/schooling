---
title: APIs and the daily allowance
version: 1
---

Salesforce has more ways in and out than most products an architect meets, and they are not
interchangeable. **Each API is built for one shape of traffic, and an integration built on the wrong
one works perfectly until the day the volume changes.** Serra Alta learnt that at a month-end close,
and the story is worth more than the catalogue, so the catalogue comes first and briefly.

## The ways in and out

| API | what it is for | shape |
|---|---|---|
| REST API | reading and writing records one at a time, or a few at a time | synchronous, JSON over HTTPS |
| SOAP API | the same operations, described by a WSDL | synchronous, XML; older integrations use it, and lesson 8 is about SOAP |
| Bulk API 2.0 | loading or extracting large volumes: tens of thousands of records and up | asynchronous: you submit a job with a CSV file and collect the results later |
| Change Data Capture | a message every time a record of a chosen object is created, changed, deleted or restored | events out of Salesforce, to subscribers |
| Platform Events | messages the org defines itself, such as *customer requested*, with API names ending `__e` | events in either direction |

The REST API also has **composite resources**, which carry several operations in one request. Two
are worth knowing by name. *Composite* sends up to 25 subrequests in one call, and later ones can
use the results of earlier ones. *sObject Collections* creates, updates or upserts up to 200 records
of one object in one call.

The two event APIs are what make Salesforce something other systems can listen to rather than
something they have to ask. A subscriber connects, usually through the Pub/Sub API, and receives
events as they happen. Each event carries a replay id, and the platform keeps recent events for a
few days, so a subscriber that was down can ask for everything after the last id it processed.
Lesson 10 is about what that needs on the subscriber's side.

## The allowance

Every org has a **daily allowance of API requests**: a total number of calls that all its
integrations together may make in any rolling 24 hours. The size depends on the edition and on how
many user licences the org has, and the org shows it in its setup screens and through the REST API's
`limits` resource. **Serra Alta's allowance is 100,000 requests per 24 hours.** On an ordinary day
the integrations other than invoices (prices and stock from SAP, orders back to it, the telephony of
the customer service centre) use about 45,000 of them.

What happens past the line matters more than the line. When an org goes over its allowance,
Salesforce can block further API calls from that org until its usage over the previous 24 hours
falls back under the total. **The block is not per integration. It is every integration in the org
at once**, including the ones that did nothing wrong.

## The month-end night

Since 2018 an IIB message flow in Rui's team has copied invoices from SAP into Salesforce's
`Invoice__c` every night, so that a rep visiting a chain can see what it owes. It was written the
obvious way. For each invoice SAP reports as new or changed, the flow makes two calls: a query to
find the Salesforce Id of the Account with that SAP customer number, then a call to create or
update the invoice.

On an ordinary night about 2,800 invoices have changed: roughly 1,400 new ones and as many paid. That
is 5,600 calls, and with the other 45,000 the day ends far under the allowance. **Nobody had
measured a month-end.** In the week of the close, finance posts the month's adjustments, the
discounts agreed with the chains, the returns and the write-offs, and reruns the overdue
calculation. Every invoice those touch counts as changed, and one night in the close the flow found
about 34,000 of them.

The arithmetic, which nobody had done in 2018:

| | requests |
|---|---|
| invoices changed that night | 34,000 |
| calls per invoice | × 2 |
| invoice sync | 68,000 |
| everything else, in the same 24 hours | 45,000 |
| total | 113,000 |
| Serra Alta's allowance | 100,000 |
| over by | 13,000 |

The flow crossed the line shortly after four in the morning. From then on every call from the org
was refused, and the one that mattered was not the invoice sync. **The 140 reps' orders, which travel
from Salesforce to SAP through the same org's allowance, stopped reaching SAP**, and the supermarket
orders taken that morning sat in Salesforce until the window rolled forward. The incident ticket
called it an outage of the order integration. The order integration had no defect at all.

## The first idea was wrong

Joana's first suggestion, in the review a week later, was to run the sync with more parallel
threads so that it finished before the reps started work. Rui pointed at the table. **The allowance
counts requests, not time.** A faster flow makes the same 68,000 calls and reaches the line earlier
in the night. The fix had to change the number of requests, and there were three ways to do it.

**Send records in sets.** sObject Collections upserts up to 200 invoices per request. And because
`SAP_Customer_Number__c` is an external id on Account, as section 03 showed, each invoice can name its
Account by that number directly, so the query that found the Salesforce Id disappears:

```json
{
  "allOrNone": false,
  "records": [
    {
      "attributes": { "type": "Invoice__c" },
      "SAP_Invoice_Number__c": "0090412337",
      "Status__c": "Paid",
      "Account__r": { "SAP_Customer_Number__c": "0000104233" }
    }
  ]
}
```

The request goes to the collection resource for `Invoice__c`, asked to upsert by
`SAP_Invoice_Number__c`, another external id. `Account__r` is how the relationship from an invoice to
its Account is named, and the platform finds the Account whose SAP number matches. **34,000 invoices
at 200 per request is 170 requests, against 68,000.**

**Send a job.** Bulk API 2.0 takes the same records as one CSV file, with a column headed
`Account__r.SAP_Customer_Number__c`, and processes it asynchronously. Creating the job, uploading the
file, closing it, asking whether it has finished and fetching the results came to eleven requests
when Rui's team tried it in the Full sandbox. Bulk API has limits of its own, counted in records and
jobs, and they are far above this load.

**Question the copy.** Does a rep need every invoice in Salesforce at all? Salesforce Connect can
show records that live in another system as *external objects*, read live through an OData service.
That would mean no nightly copy, and also an OData service on SAP that must answer whenever a rep
opens an account, through the Sunday window, and the question of indirect access from lesson 1, now
for 140 people. Joana wrote it down as an option and did not take it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-calls\" aria-label=\"Three horizontal bars on one scale, the API requests used in 24 hours on the month-end night. Each bar starts with the 45,000 requests of the other integrations. The first adds 68,000 for two REST calls per invoice and reaches 113,000, past an amber line at Serra Alta's allowance of 100,000. The second adds 170 requests for sObject Collections of 200 invoices each. The third adds 11 requests for one Bulk API 2.0 job. The last two additions are too small to see at this scale.\"><text x=\"208.0\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">two REST calls per invoice</text><rect x=\"220.0\" y=\"67.0\" width=\"136.8\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"356.8\" y=\"67.0\" width=\"206.7\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"571.5\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">113,000</text><text x=\"208.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sObject Collections, 200 per call</text><rect x=\"220.0\" y=\"129.0\" width=\"136.8\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"356.8\" y=\"129.0\" width=\"1.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"365.3\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45,170</text><text x=\"208.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one Bulk API 2.0 job</text><rect x=\"220.0\" y=\"191.0\" width=\"136.8\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"356.8\" y=\"191.0\" width=\"1.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"364.8\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45,011</text><path d=\"M524.0 46.0 L524.0 63.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M524.0 97.0 L524.0 236.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"524.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">allowance: 100,000 per 24 h</text><path d=\"M220.0 236.0 L600.0 236.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M220.0 236.0 L220.0 241.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"220.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M372.0 236.0 L372.0 241.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"372.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50,000</text><path d=\"M524.0 236.0 L524.0 241.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"524.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100,000</text><rect x=\"220.0\" y=\"268.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">other integrations, 45,000</text><rect x=\"450.0\" y=\"268.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the invoice sync</text></svg>", "caption": "The month-end night three ways, on one scale. Only the first crosses the allowance; the other two change the number of requests, not the speed."}
```

## What the sandbox found

Rui's team built the collection version first, because it changed the least, and ran a month-end's
worth of invoices through it in the Full sandbox. The first collection of 200 failed with
`Too many SOQL queries: 101`.

The cause was a trigger from 2018 on `Invoice__c`. For each invoice saved, it queried the Account to
update a field showing whether the customer had anything overdue, one query per invoice inside a
loop. **A trigger receives the records of a save in chunks of up to 200.** While the flow sent one
invoice per call, every transaction held one invoice and made one query. Sent 200 at a time, the
same trigger tried 200 queries in one transaction and crossed the limit of section 02 at the 101st,
and the platform rolled back the whole chunk.

The fix was the standard one: collect the Account Ids of all the invoices in the chunk, run one query
for all of them, and update the Accounts in one statement. It took the partner a day. **Finding it
took a test at production volume**, which is what the Full sandbox exists for, and is why the change
did not reach production on a Friday as first planned.

## What Serra Alta runs now

| | before | after |
|---|---|---|
| nightly invoices | 2 REST calls per invoice | one Bulk API 2.0 job |
| invoices changed in the day | none; they waited for the night | sObject Collections, up to 200 per call |
| the trigger on `Invoice__c` | one query per invoice | one query per chunk |
| watching the allowance | nobody | the `limits` resource read every 15 minutes; Rui's team is alerted at 70% |

**The decision Joana recorded was not "use the Bulk API".** It was that every integration with
Salesforce declares how many requests it makes on an ordinary day and on the worst day of the month,
and that the sum is checked against the allowance before a new one goes live. The allowance is a
budget the whole org shares, and until that night nobody was keeping it.
