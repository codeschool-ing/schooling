---
title: The LGPD and the GDPR, side by side
version: 1
---

For a team that already works under the LGPD, the GDPR is mostly the same obligations with different
numbers. The numbers are where the mistakes happen.

| | LGPD | GDPR |
|---|---|---|
| legal bases | ten (art. 7) | six (art. 6(1)): consent, contract, legal obligation, vital interests, public task, legitimate interests |
| credit protection as a basis | yes (art. 7, X) | no — usually legitimate interest |
| sensitive data | art. 11, a list of exceptions | art. 9, "special categories", a list of ten exceptions |
| children | consent of a parent, in the child's best interest (art. 14) | for online services, a parent's consent below **16**, which a member state may lower to 13 (art. 8) — Portugal chose **13** |
| DPO | the controller appoints one, with exemptions for small agents | required for public bodies and where the core activity is large-scale monitoring or large-scale special categories (art. 37) |
| answering a request | access within 15 days (art. 19) | **one month**, extendable by two for complex requests (art. 12(3)) |
| breach notice to the authority | 3 working days (Resolução 15/2024) | **72 hours**, where feasible (art. 33) |
| impact assessment | when the ANPD asks (art. 38) | **required** for processing likely to result in high risk (art. 35) |
| maximum fine | 2% of revenue in Brazil, up to R$ 50 million per infraction | **4% of worldwide annual turnover or €20 million**, whichever is higher (art. 83(5)) |

## Rights that are named differently

The GDPR lists the rights as separate articles: access (15), rectification (16), erasure (17),
restriction (18), portability (20), objection (21), and not being subject to a solely automated
decision (22). Two of them deserve a second look:

- **Restriction** (art. 18) is the GDPR's version of the LGPD's *bloqueio*: the data is kept but not
  used, while a dispute about its accuracy or lawfulness is settled. In a database it is a flag that
  every query of every purpose has to respect — and therefore a column that `consent_now` in lesson 7
  would have had to learn about.
- **Objection** (art. 21) is absolute for direct marketing: once a person objects, the marketing stops,
  with no balancing test. The LGPD reaches the same place by revoking consent, or by article 18, §2
  when the basis is another one.

## The habit that transfers

Lesson 7's tables carry over with one addition. `gov.subject_requests` had a due date of 15 days for
everything; a request from a Lisbon customer is due in a month. **The due date depends on the law, and
the law depends on the row** — so the generated column becomes a rule over two columns, and a request
from Portugal answered on day 20 is on time while one from São Paulo is late. A team that keeps one
number in its head keeps the wrong one for half its customers.
