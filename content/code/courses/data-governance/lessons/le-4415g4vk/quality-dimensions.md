---
title: What "good data" means
version: 1
---

**Data quality is fitness for a purpose**, and the purpose matters: an address that is good enough
for a sales report by state is not good enough to deliver a parcel. That is why quality is not one
number. It is a set of questions, usually called **dimensions**, each with its own test:

| dimension | the question | at Ipê |
|---|---|---|
| **validity** | does the value have the allowed shape and range? | an e-mail without `@`; an order dated next year |
| **uniqueness** | is each thing recorded once? | the same customer signed up twice |
| **completeness** | is everything that should be there, there? | an order with no customer |
| **consistency** | do two places that should agree, agree? | a payment that differs from its order; consent before the account existed |
| **timeliness** | is it up to date when it is used? | a stock level from yesterday's load |
| **accuracy** | does it match the real world? | an address the customer has moved from |

The last one is different in kind. The first five can be measured **inside the database**, with a
query. Accuracy needs something outside it — the customer, the courier, a document — and most
programmes measure it by sampling: call fifty customers, compare. A quality report that claims to
measure accuracy with SQL alone is measuring one of the others.

## Why governance cares

Bad data is a privacy problem as well as a business one, which is why it sits in this course and why
the LGPD lists **data quality** among its principles (lesson 7): accurate, clear, relevant and up to
date. Each defect below breaks something the earlier lessons built:

- **a duplicate customer** is a person whose access request returns half their data, and whose erasure
  request leaves the other half behind (lesson 7);
- **a malformed e-mail** is a customer who never received the notice of an incident (lesson 7);
- **a consent recorded before the account existed** is a consent nobody can prove (lesson 7, article
  8).

The next section measures them.
