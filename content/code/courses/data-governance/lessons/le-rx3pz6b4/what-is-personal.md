---
title: What makes data personal
version: 1
---

The LGPD's definition is one line, and most of the law hangs from it. **Article 5, I**: personal
data is *information related to an identified or identifiable natural person.*

Two words in it carry the weight.

**"Related to"** is wide. It is not only data *about* somebody, like a name or a date of birth, but
anything that says something about them: an order placed, a ticket written, the time a delivery
arrived, the fact that they accepted marketing. A table of orders with no names in it is a table of
things people did.

**"Identifiable"** is wider. A person does not have to be named in the data; it is enough that they
*can* be identified, by the controller or by somebody else, with the data and other information.
Ipê's `customer_id` 2 names nobody — and joins to a row with a name, an e-mail and a CPF. An order
row with `customer_id = 2` is therefore personal data, and so is everything that joins to it.

Lesson 5 measured how far that reaches: with no identifier at all, birth date, sex and CEP single out
5,988 of 6,012 customers. **Most of the data in a company's operational database is personal data**,
and the useful question is rarely "is this personal?" but "how directly does it identify, and what
does it reveal?"

## What is not personal data

- **Data about a company**, not a person: a supplier's tax number, a shop's address. (A sole trader's
  is about a person.)
- **The catalogue**: Ipê's products and their prices say nothing about anybody until somebody buys
  one.
- **Anonymised data** in the sense of lesson 5 — measured, and while the measurement holds.
- **Data about people who have died** is generally read as outside the LGPD's definition, which
  speaks of a living natural person's rights; other rules — medical confidentiality among them —
  still apply to it.

## Who is who

The law names roles that the rest of the course uses:

| role | in the LGPD | at Ipê |
|---|---|---|
| **titular** (data subject) | the person the data is about | each customer |
| **controlador** (controller) | who decides why and how data is processed | Farmácia Ipê |
| **operador** (processor) | who processes it on the controller's behalf | the payment provider, a cloud host |
| **encarregado** (DPO) | the channel between controller, data subjects and the authority | Davi |

The controller is responsible for what the processor does with the data it was given. Lesson 7 puts
duties on each.
