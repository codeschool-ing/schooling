---
title: Two ERPs in one group
version: 1
---

Serra Alta runs SAP and Mantiqueira runs Business Central, so since 2021 the group has had two ERPs,
and somebody has to decide whether that is a passing state or the design. There are three serious
options: move Mantiqueira into SAP, keep both and connect their operations, or keep both and join
them only in the group's accounts. **The choice turns less on either product than on a date**: SAP's
mainstream maintenance for ECC ends at the end of 2027.

## What the acquisition left

Mantiqueira is still a separate legal entity, with its own CNPJ and its own books, owned by Serra
Alta. Sales between the two run both ways. Serra Alta sells Mantiqueira the milk its trucks collect
for the Alagoa plant, and Mantiqueira sells Serra Alta about 60% of its cheese, which goes to the
supermarket chains alongside the rest of Serra Alta's range. The other 40% Mantiqueira sells
directly to about 300 shops and restaurants in the south of Minas Gerais, customers it had long
before the acquisition.

Every intercompany sale is a sale between two companies, so each needs its own NF-e, and each is
typed twice: issued in one ERP and keyed by hand into the other. That is about 180 invoices a month
and two days of an accounts-payable clerk's time, and the differences surface at month end.

Month end is the other half. Serra Alta's own books close in the first five working days (lesson 1).
The group's do not, because Marcos Teles's controllers build the consolidated accounts in a
spreadsheet. They export Mantiqueira's trial balance from Business Central, map its 212 accounts by
hand onto Serra Alta's group chart of accounts, eliminate the intercompany balances and add the
result to SAP's figures. It takes until the ninth working day. Marcos wants the group closed on the
fifth, like the company.

## Joana's first answer

Joana's first draft recommended one ERP. It followed straight from lesson 1: one database for the
whole business, one document flow from order to cash, and no reconciliation because nothing is
copied. Mantiqueira would become another company code in Serra Alta's SAP, its 41 users would
become SAP users, and Business Central would be switched off.

Edson Prado read it and asked one question: into which SAP? The ECC system Mantiqueira would move
into leaves mainstream maintenance at the end of 2027, and the S/4HANA project that replaces it is
already being planned (lesson 2). **Migrating a company into a system you are about to leave means
migrating it twice**: once into ECC, then again with everything else into S/4HANA a few years
later. Mantiqueira's two cheese extensions would be rebuilt in ABAP for ECC, and then reconsidered
for S/4HANA. Joana had seen the right shape, since one ERP for the group is a reasonable end state,
at the wrong moment.

## The three options

Edson's question turned one proposal into three, and Joana costed each with Edson, Felipe Arruda and
the SAP consultancy. The figures are Serra Alta's own estimates, not market prices.

| | A: Mantiqueira into SAP ECC | B: both, integrated in operations | C: both, consolidated in finance |
|---|---|---|---|
| what crosses between the ERPs | everything, once: customers, items, open orders, stock, balances | orders, deliveries, invoices, items and prices, every day | a monthly trial balance and the intercompany balances |
| estimate | R$ 2.1 million, 9 months | R$ 650 thousand, 5 months | R$ 190 thousand, 3 months |
| what it leaves behind | a second migration in the S/4HANA project | about twelve new integration flows to run, and two ERPs coupled through them | two ERPs with separate operations |
| the risk Joana wrote down | the cheese plant moved onto a system leaving maintenance | a change in either ERP breaks the other's document flow | the consolidation is only as good as the account mapping |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l03-options\" aria-label=\"Three panels, one per option, each with SAP ECC above and Business Central below. Option A, Mantiqueira into SAP ECC: one arrow carries everything once, Business Central is switched off, and the move is repeated in the S/4HANA project; R$ 2.1 million and 9 months. Option B, integrated in operations: five arrows in both directions for orders, deliveries, invoices, items and prices, every day; R$ 650 thousand, 5 months and about twelve flows to run. Option C, consolidated in finance: one arrow, the trial balance, once a month; R$ 190 thousand and 3 months.\"><defs><marker id=\"l03-options-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"8.0\" width=\"226.0\" height=\"314.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"123.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">A: into SAP ECC</text><rect x=\"48.0\" y=\"53.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"123.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"48.0\" y=\"193.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"123.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"123.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 2.1 million, 9 months,</text><text x=\"123.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">then again into S/4HANA</text><path d=\"M123.0 192.0 L123.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2.4\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><text x=\"131.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">everything, once</text><text x=\"123.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">switched off</text><rect x=\"247.0\" y=\"8.0\" width=\"226.0\" height=\"314.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">B: integrated in operations</text><rect x=\"285.0\" y=\"53.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"285.0\" y=\"193.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"360.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 650 thousand, 5 months,</text><text x=\"360.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">~12 flows to run</text><path d=\"M300.0 192.0 L300.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M330.0 89.0 L330.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M360.0 192.0 L360.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M390.0 89.0 L390.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><path d=\"M420.0 192.0 L420.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">orders, deliveries, invoices,</text><text x=\"360.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">items, prices: every day</text><rect x=\"484.0\" y=\"8.0\" width=\"226.0\" height=\"314.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"597.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">C: consolidated in finance</text><rect x=\"522.0\" y=\"53.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"597.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"522.0\" y=\"193.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"597.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"597.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 190 thousand, 3 months,</text><text x=\"597.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one monthly read</text><path d=\"M597.0 192.0 L597.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-options-es-ah-paper-dim)\"></path><text x=\"605.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">trial balance,</text><text x=\"605.0\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">monthly</text></svg>", "caption": "What crosses between the two ERPs under each option. The count of arrows is the coupling, and the cost of B is the one that keeps coming after the project ends."}
```

Option B is the one that looks most like architecture, and it is the one Joana argued against
hardest. It connects two document flows: a Serra Alta purchase order would create a Mantiqueira
sales order, a delivery in Business Central would post a goods receipt in SAP, and an invoice in one
would create a payable in the other. Each of those links is a dependency between two systems that
are customised, upgraded and closed on their own calendars. SAP alone is down every Sunday night for
maintenance, and frozen during its own close. **Coupling two ERPs' document flows gives you the
costs of one system and the independence of neither**, and it would do so for exactly the years in
which SAP is being replaced underneath it.

## How the integration would work

Under any option, something has to read Business Central. It publishes a REST API built on OData
version 4, with standard endpoints for what a finance integration needs (customers, items, sales
invoices, the general ledger), and a partner or a customer can publish more as AL extensions. Calls
are authenticated through Entra ID, and an application registered in the tenant can call the API
with no person signed in, which is how a scheduled integration ought to identify itself.

The tenant is Mantiqueira's old one. That is the loose end from the previous section coming back:
the integration's own identity would live in the directory nobody governs, with a secret only Felipe
holds. Joana's plan registers it there anyway, because the move is not scheduled, and adds two
things. The secret goes into the vault Rui Andrade's team uses, with its expiry date on their
calendar. And moving Business Central into Serra Alta's tenant goes onto the S/4HANA project's list
instead of nobody's.

On the SAP side the integration uses the doors lesson 2 describes and runs on Rui's platform, like
every other flow into SAP. Lessons 9 to 11 are about how such a flow should be built.

One integration pays off under every option, and it needs neither ERP's API. When Mantiqueira sells
cheese to Serra Alta, SEFAZ authorises an NF-e: an XML document carrying every line, quantity, price
and tax of the sale, signed and already validated by the tax authority. The seller sends that XML to
the buyer. **The data the clerk re-types every month already arrives at Serra Alta, structured and
authorised.** Loading it into SAP instead of typing it removes the re-keying under A, B and C alike,
and the same holds in the other direction for the milk.

## The recommendation

Joana's recommendation, as she wrote it for Regina and Marcos:

- consolidate at the finance level now, which is option C. Each month, once Mantiqueira has closed
  its books, an integration reads the trial balance through the Business Central API, maps it
  through a table of accounts that Marcos's controllers own, and matches and eliminates the
  intercompany balances before the group report is produced;
- load the intercompany NF-e XML on both sides instead of re-keying it;
- keep Mantiqueira's operations on Business Central, and put a support contract with a Business
  Central partner behind Felipe, who is Mantiqueira's only IT person;
- decide again inside the S/4HANA project, where the question becomes whether Mantiqueira is one
  more company in the new system: designed once, migrated once.

The estimate was R$ 240 thousand and four months. Marcos accepted it because it put the group close
on the fifth working day. Edson accepted it because it added nothing to ECC. Felipe was relieved to
keep the system he knows, and uneasy about what the S/4HANA decision would mean for him. Joana
recorded that as a risk, because a system that one person understands is a system with one point of
failure.

**Coexistence here is a decision and not a default**: it has a reason, a cost, a date to revisit it
and an owner for each piece. Two ERPs that nobody decided to keep are the same two systems with none
of those. Lesson 13 comes back to coexistence as a deliberate state, when Coleta is being replaced,
and lesson 15 to choosing what to build and what to buy.
