---
title: Who owns the customer
version: 1
---

Two systems at Serra Alta hold a record called a customer. SAP has about 9,800 of them, every
company it sells to. Salesforce has about 3,100 Accounts, the supermarket chains, their stores and
the distributors that the 140 reps look after. **Nearly every one of those Accounts is also one of
SAP's customers, described twice, by two systems that change on different days for different
reasons.** The architecture question is not which system is right. It is which system is allowed to
be right about each fact.

## The wrong answer Joana gave first

In her third week Joana proposed that Salesforce become the customer master. Her reasons were good
ones. A customer appears in Salesforce first, as a prospect, months before anybody in SAP hears of
it. The reps know the buyers, the visits and the complaints, and SAP knows none of that. Salesforce
has a cleaner interface and a better API. At the fintech, the system closest to the customer owned
the customer.

Marcos Teles, the CFO, answered in one sentence: the customer is whoever we invoice. **An NF-e
cannot be issued without the legal name, the CNPJ, the state tax registration and the fiscal address,
and SAP is the system that issues it**, books the receivable, checks the credit limit and collects
the money. If Salesforce owned those fields, every invoice would depend on a copy arriving in SAP on
time and intact, and a wrong CNPJ would be a rejected invoice at SEFAZ rather than a typo in a CRM.

Joana withdrew the proposal the same afternoon. What she kept from it was the right question: not
which system owns the customer, but **which system owns each field**.

## Ownership is per field, not per record

Lesson 1 separated master data from transactional data. The customer is master data, and at Serra
Alta it is split down the middle:

| field or record | system of record | on the other side |
|---|---|---|
| legal name, CNPJ, state tax registration | SAP | read-only copy in Salesforce |
| fiscal address | SAP | read-only copy in Salesforce |
| sold-to, ship-to, bill-to and payer structure | SAP | read-only in Salesforce, as the account hierarchy |
| credit limit and payment terms | SAP | read-only in Salesforce; a rep asks for a change, never types one |
| open invoices and what is overdue | SAP | the nightly copy in `Invoice__c` |
| contacts: the buyers, the category managers | Salesforce | not in SAP |
| opportunities, visits, notes | Salesforce | not in SAP |
| cases: complaints, recall questions | Salesforce | the quality data behind them stays in SAP and Documentum |
| the rep who owns the account | Salesforce | sent to SAP for the sales reports |

Every row has **exactly one system that may change the value**, and every copy is read-only where
it lands. In Salesforce that is enforced, not requested: field-level security and the page layouts
make the SAP-owned fields uneditable for everybody but the integration's own user.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l04-ownership\" aria-label=\"SAP ECC on the left and Salesforce on the right, each listing the fields it owns. SAP owns the legal name, CNPJ and state registration, the fiscal address, the sold-to, ship-to, bill-to and payer structure, the credit limit and payment terms, and the invoices with what is overdue. Salesforce owns contacts, opportunities and visits, cases, and the rep who owns the account. Between them, a solid arrow from SAP to Salesforce carries read-only copies of SAP's fields every night; a dashed arrow from Salesforce to SAP carries the request to create a customer. At the bottom, the two ids each side keeps: the SAP customer number on the Account, as a unique external id, and the 18-character Salesforce Id on the SAP customer.\"><defs><marker id=\"l04-ownership-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-ownership-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15.0\" y=\"20.0\" width=\"230.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC</text><text x=\"130.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">owns what is invoiced</text><rect x=\"27.0\" y=\"80.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">legal name, CNPJ, state registration</text><rect x=\"27.0\" y=\"112.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fiscal address</text><rect x=\"27.0\" y=\"144.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sold-to, ship-to, bill-to, payer</text><rect x=\"27.0\" y=\"176.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">credit limit, payment terms</text><rect x=\"27.0\" y=\"208.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">invoices and what is overdue</text><rect x=\"475.0\" y=\"20.0\" width=\"230.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Salesforce</text><text x=\"590.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">owns the relationship</text><rect x=\"487.0\" y=\"80.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contacts: buyers, category managers</text><rect x=\"487.0\" y=\"112.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">opportunities and visits</text><rect x=\"487.0\" y=\"144.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cases: complaints, recalls</text><rect x=\"487.0\" y=\"176.0\" width=\"206.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the rep who owns the account</text><path d=\"M250.0 112.0 L470.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-ownership-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"133.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nightly: read-only</text><text x=\"360.0\" y=\"146.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copies of SAP's fields</text><path d=\"M470.0 196.0 L250.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-ownership-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"215.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">request to create</text><text x=\"360.0\" y=\"228.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new customer</text><rect x=\"15.0\" y=\"270.0\" width=\"690.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the ids each side keeps</text><text x=\"190.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on the SAP customer:</text><text x=\"190.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the 18-character Salesforce Id</text><text x=\"530.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on the Account, unique external id:</text><text x=\"530.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SAP_Customer_Number__c</text></svg>", "caption": "One owner per field. Each copy is read-only where it lands, and each side stores the other's id, so nothing has to be matched by name or by CNPJ."}
```

Serra Alta learnt the read-only rule the expensive way. Until 2021 the fiscal address could be
edited in both systems, and a sync ran in each direction. A rep corrected a distributor's address in
Salesforce after it moved; that night the SAP-to-Salesforce sync, which ran later, wrote the old one
back. The next NF-e went to the old address, the delivery went to the new one, and the distributor's
receiving team refused the load because the documents did not match. **A field that two systems may
both change is a field where the last sync to run wins, silently, and nobody is told there was a
contest.**

## The golden record, and the duplicates under it

The industry's name for the single trusted version of a customer is the **golden record**, and the
discipline of keeping it is **master data management**. Large companies buy tools for it; SAP's own
is Master Data Governance, where requests to create or change a customer go through approval before
they reach the ERP. Serra Alta has no such tool. In practice SAP is its golden record for the legal
customer, and the field table above is its governance.

A golden record does not stop duplicates from being typed. In 2025 Talita matched every Account in
Salesforce against every other by CNPJ and found **214 pairs of Accounts that were the same company**.
Most had the CNPJ typed once with its dots, slash and dash and once as fourteen digits. Some had it
missing on one side. Reps had created the second copy because they could not find the first.

Salesforce has the tools for the first half of the cure: **matching rules** decide when two records
look like the same company, and **duplicate rules** decide what happens then, a warning or a refusal
at the moment of saving. Serra Alta's rule now compares the CNPJ stored as digits only and refuses a
second Account with the same one. The second half, merging 214 pairs without losing the visits and
cases hanging off each, took Talita a month.

**A CNPJ finds duplicates; it is not the key two systems join on.** Its first eight digits identify
the company and the next four the branch, so a chain's stores share a root and differ after it.
SAP may also hold more than one customer number for one CNPJ: a sold-to and a separate payer, or the same
company in two sales areas. A join on CNPJ would put the wrong invoices against the wrong Account the
first time that happened. The join is on ids, and both systems store the other's.

## Ids on both sides

**Each Account carries its SAP customer number, and each SAP customer carries its Salesforce Id.**
The first is `SAP_Customer_Number__c`, the field shown as a file in section 03: ten characters, an
external id, unique. Being an external id is what let section 04's invoices name their Account by
SAP number with no lookup. Being unique is what stops a second Account claiming the same SAP
customer.

The second is a custom field Edson's team added to the customer master in SAP. It holds the Account's
Salesforce Id, and **it holds the 18-character form**. A Salesforce record id comes in two forms: 15
characters that are case-sensitive, and 18 characters, the same 15 with three more that encode the
capitals, so that the id stays unique when compared without regard to case. SAP's search screens,
spreadsheets and half the tools in an integration compare without regard to case. Store the
15-character form and two different Accounts can, one day, look like the same one.

## The customer Salesforce knows first

A new customer is born in Salesforce and becomes real in SAP, and the sequence between is where the
two ownerships meet:

1. A rep creates an Account for a regional chain as a prospect. It has a name, contacts and an
   opportunity, and no SAP customer number.
2. The opportunity is won. The rep fills in the fiscal data and asks for the customer to be created,
   which publishes a Platform Event.
3. An IIB flow receives the event and starts the credit approval process in IBM BPM, which lesson 6
   describes. Finance approves a limit and payment terms.
4. SAP creates the customer, with its number, its credit limit and its partner structure, and stores
   the Account's Salesforce Id.
5. The flow writes the SAP number back into `SAP_Customer_Number__c`, and the Account becomes a
   customer.
6. Only now can an order for it be sent to SAP. A validation rule refuses an order on an Account with
   no SAP number.

**The window between steps 1 and 5 is legitimate, and the design has to say what is allowed in
it.** At Serra Alta a prospect may have contacts, visits and opportunities, and may not have an
order, a credit limit or a price list, because those are SAP's to give. When step 3 says no, the
Account stays a prospect, and the rep sees why on the Account, with the reason finance gave.

That is the shape Joana ended with, and it gave her original proposal what it was right about. The
customer does start in Salesforce. It just does not become a customer there.
