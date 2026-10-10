---
title: One question, four people
version: 1
---

The table in the last section makes the roles look like separate departments. In practice **one
business question passes through several of them, and each does a different part of it.** Following
one question from the person who asked it to the decision it served shows where each role starts and
stops — and at Varanda, how few people there are to fill them.

## Renata's question

In February 2026 Renata Sá, the marketing director, asked Lívia: "Which customers will come back?"
She was planning a May campaign for the online shop and wanted to spend its budget on the people
most likely to buy a second time, instead of on everybody who had ever bought once.

It sounds like one question. It is at least four.

## The engineer's part: can a customer be followed at all?

To know whether somebody came back, the data has to recognise them the second time. The online shop
does: every order belongs to an account. The stores mostly do not, because a customer who pays at the
till is anonymous unless they give an e-mail for the loyalty programme. **Before anybody could
analyse returning customers, Tiago had to build a customer table from the online shop's accounts and
copy it into the database every night**, with each order linked to its account. He also decided,
and wrote down, that the first version would cover the online shop only.

That is engineering: no business question answered, and nothing else possible without it.

## The data analyst's part: what does the data say, once?

Lívia then did a data analyst's work. She took every customer whose first ever online order was
placed in the first half of 2025, so that each had had at least 180 days to come back by the end of
the year: **41,200 of them.** Of those, **11,900 ordered again within 180 days of their first order,
or 28.9%.** Then she looked for differences: by the category of the first purchase,
by the month, by whether the first order was delivered late. She did not know at the start which
comparison would matter, and most of them did not.

What she found was modest and useful. Of the 2,600 customers whose first order arrived late, 21.9%
came back; of the 38,600 whose first order arrived on time, 29.4% did. That went to Caio as well as
to Renata.

## The BI analyst's part: the same answer, every month

Renata liked the number and asked to see it every month. At that moment the work changed kind.
**A number that will be shown monthly needs a written definition that does not move**: who counts as
a first-time customer, what "again" means (another paid order, not a cancelled one), why 180 days and
not 90. Lívia wrote it down, gave the measure a name — repeat rate — and added it to the online shop's
monthly report. The calculation was the same as the exploration's; what made it BI was the
definition and the repetition.

## The data scientist's part: which customer, exactly?

Renata's original question was about individual customers: which ones will come back. A repeat rate
of 28.9% answers "how many", not "which". **Scoring each customer by their chance of returning is a
model, and it is a data scientist's job.** Varanda has nobody to do it. Lívia said so, and offered
the simple version she could defend: send the campaign to 2025 first-time customers whose first order
arrived on time, since that group came back more. If the campaign works and Varanda wants to go
further, a model is the next step, and it is worth paying for only if it beats that rule.

## What to take from it

Four kinds of work, two people, one question. Tiago did the first and Lívia did the next two; the
fourth was named and not done. **The useful skill is not doing all four. It is recognising which one
a request needs**, saying which ones nobody at the company can do yet, and offering the honest
version that fits the people there are.
