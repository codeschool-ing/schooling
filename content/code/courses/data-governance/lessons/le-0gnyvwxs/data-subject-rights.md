---
title: The data subject's rights
version: 1
---

The person a piece of data is about is the **data subject** (*titular*). **Article 18** gives them
nine rights against the controller, each of which a data team ends up implementing as a query, a
script or a procedure:

| | the person may ask for | what it means in the database |
|---|---|---|
| I | **confirmation** that their data is processed | does any row point at them? |
| II | **access** to the data | every row about them, readable |
| III | **correction** of incomplete, wrong or outdated data | an `UPDATE`, and a record that it was asked |
| IV | **anonymisation, blocking or deletion** of data that is unnecessary, excessive or processed unlawfully | finding what was never needed — lesson 6's minimisation |
| V | **portability** to another supplier, on express request | the same export as II, in a format another system can read |
| VI | **deletion** of data processed with their consent, except where article 16 allows keeping it | section 10 |
| VII | **information on who the data was shared with** | the record of processing knows, or nobody does |
| VIII | **information on the option of not consenting**, and what follows from refusing | the wording of the form |
| IX | **withdrawal of consent** | section 6's events |

Four paragraphs of the same article shape how they are answered. The request is made **expressly**,
by the person or a legal representative (§3). It costs the person **nothing** (§5). If the
controller cannot act at once, it must say why, or say that it is not the controller and name who
is (§4). And when data is corrected, deleted, anonymised or blocked, the controller must **tell the
other agents it shared the data with**, so they do the same (§6) — which is only possible if
somebody wrote down who those are.

## Two rights beyond article 18

**Article 9** gives the person a right to *facilitated access* to information about the processing:
its purpose, its form and duration, who the controller is and how to reach them, who the data is
shared with and why, and their rights. That is the privacy notice, and lesson 6's record of
processing is what it should be written from, not the other way round.

**Article 20** lets the person ask for a **review of a decision taken solely on automated
processing** that affects their interests, profiling included — a credit score, a fraud flag that
cancels an order. The controller must explain, when asked, the criteria and procedures behind the
decision, protecting trade secrets. The text first published said the review would be made by a natural
person; the 2019 reform (Law 13,853) left those words out, so the law does not demand a human in the
review. A fraud model that cancels orders without anybody looking still has to be explainable to
the customer it cancelled.

## What the rights demand of the data

Reading the table again as an engineer, three things stand out:

- **You must be able to find everything about one person.** Rights I, II, V and VI all begin there.
  A customer id that some tables carry and others reach through a join, and a free-text field where
  somebody typed a CPF, are where the search goes wrong.
- **You must keep records of the requests themselves** — what was asked, when, what was answered —
  because the deadline of section 9 and the burden of proof of section 6 both apply.
- **You must know who you gave the data to**, because §6 makes the controller pass the request on.

Lesson 6 built the first of these, the classification in `gov.column_class`. The next section uses
it.
