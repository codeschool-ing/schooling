---
title: What compliance reporting is
version: 1
---

Every report in this course so far was asked for by somebody inside the company, and the company
chose its definitions, its deadline and whether to produce it at all. **A compliance report is the
one somebody outside requires: the definition is theirs, the deadline is theirs, and missing either
has a penalty.** That changes how the work is done more than what the work is, and this lesson is
about the change.

Lessons 17 to 20 read four industries with lesson 17's four questions. Compliance is not an
industry; it is a layer every industry has. So this lesson asks the questions once for that layer:

| lesson 17's question | for compliance reporting |
|---|---|
| the decisions made over and over | none of them the company's own: the decision belongs to a regulator, an auditor or a tax authority, and the company supplies the evidence |
| the indicators that serve them | whatever the rule defines, in the rule's words, and nothing the company may redefine |
| the data, and what is odd about it | it has to be the data **as it stood on a date**, and it has to be possible to show it again years later |
| the typical trap | two numbers with one name, the outside one and the inside one, quietly made to agree |

## Who asks, by industry

The examples below are stated at the level of what every company in the industry knows. The rules
themselves are long, change often and are the job of a company's legal and compliance staff; the
BI analyst's part is producing the numbers they require, the same way every time.

- **Everybody reports to the tax authority.** In Brazil that is the Receita Federal, and companies
  send their tax and accounting records to it electronically through the public digital bookkeeping
  system, SPED. Varanda's sales, purchases and payroll all end up there. A number in those files
  that does not match the accounts is not a reporting mistake to fix next month; it is a tax
  problem.
- **A lender reports to the Central Bank.** Ipê Crédito, from lesson 17, sends data about its
  customers' loans to the Central Bank's credit information system, the SCR, and the Central Bank
  sets how loans are classified and what counts as overdue for those reports.
- **A hospital reports to the health authorities.** Jacarandá, from lesson 19, has to notify cases
  of certain diseases to public health surveillance, and reports what it does for patients of the
  public health system, SUS, which is also how it is paid for them.
- **Anybody who holds personal data answers to the LGPD**, enforced by the ANPD: Varanda for its
  customers and employees, Ipê for its borrowers, Jacarandá for its patients. The LGPD asks for
  fewer periodic reports than the others and more answers on demand, which is the subject of this
  lesson's section on the law.

## What changes for the analyst

**The definition is not yours to choose.** Lesson 10's KPI card has a line for the formula, and for
an internal KPI the company writes it. For a compliance report the line is copied from the rule,
word for word, with the rule's name and version beside it. If the rule is ambiguous, the answer
comes from the compliance team or the regulator, in writing, and the written answer is kept.

**The deadline is not a target.** A monthly sales email that arrives at eleven instead of nine is a
nuisance. A regulatory file that arrives a day late can carry a fine, and the work is planned
backwards from the date, with the snapshot frozen and the review done days before.

**And the report is evidence.** An internal dashboard that was wrong last March is corrected and
forgotten. A report sent to a regulator last March stays sent, and if anybody asks about it in two
years the company has to show how each number was produced. **That one requirement is why compliance
reporting is the strictest form of the BI defined in lesson 1**: records turned into answers the
same way every time, and able to prove it.

Ipê keeps all of its obligations on one page, which is an operational screen in lesson 14's sense,
for reports instead of deliveries:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A mock of Ipê's compliance calendar on Monday 12 January 2026. Five rows, each with the report, how often it is due, its owner and its status: the Central Bank's credit data, monthly, Fernanda, snapshot frozen and in review; the monthly tax filing, finance, submitted and archived; the board's risk appetite report, Fernanda, not started and due in 9 days; data subject requests under the LGPD, the privacy officer, 2 open, the oldest 6 days old; the annual audit of the loan book, finance, the 31 December snapshot kept.\" data-fig=\"l21-calendar\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"310.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Ipê · compliance calendar</text><text x=\"692.0\" y=\"40.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Mon 12 Jan 2026</text><text x=\"28.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">report</text><text x=\"290.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">due</text><text x=\"400.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">owner</text><text x=\"505.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">status</text><path d=\"M28.0 84.0 L692.0 84.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M18.0 100.0 H22.0 V116.0 H18.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"28.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Central Bank: credit data (SCR)</text><text x=\"290.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">monthly</text><text x=\"400.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Fernanda</text><text x=\"505.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">snapshot frozen, in review</text><text x=\"28.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tax authority: monthly filing</text><text x=\"290.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">monthly</text><text x=\"400.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">finance</text><text x=\"505.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">submitted, archived</text><text x=\"28.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Board: risk appetite report</text><text x=\"290.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">monthly</text><text x=\"400.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Fernanda</text><text x=\"505.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">not started: due in 9 days</text><path d=\"M18.0 214.0 H22.0 V230.0 H18.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"28.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Data subject requests (LGPD)</text><text x=\"290.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">as they come</text><text x=\"400.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">privacy officer</text><text x=\"505.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2 open, oldest 6 days</text><text x=\"28.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Annual audit: loan book</text><text x=\"290.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">yearly</text><text x=\"400.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">finance</text><text x=\"505.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">snapshot of 31 Dec kept</text><text x=\"28.0\" y=\"304.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each submitted report keeps: snapshot date, definition version, approver</text></svg>", "caption": "A compliance calendar is an operational screen for reports: what is due, whose it is, and whether it can be reproduced. The rows that need somebody this week are marked."}
```
