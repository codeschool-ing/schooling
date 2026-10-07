---
title: Numbers that are really names
version: 1
---

A column written in digits is not necessarily numerical. The question is never "is it a number?" but
**"does arithmetic on it mean anything?"**

Horta's *postcode* is the clearest case. `13025-320` is written in digits, but it names a stretch of
street. Strip the hyphen and average the twelve postcodes and you get 13,044,475.83, which is not a
postcode, is not a place and is not anything. Two orders sharing a postcode tells you they went to the
same street. Subtracting two postcodes tells you nothing.

## The test, applied

Ask what the average would mean, in a sentence a manager could act on.

| column | written as | average means | kind |
|---|---|---|---|
| basket | 86.40 | the typical amount spent | numerical |
| items | 7 | the typical number of things bought | numerical |
| postcode | 13025-320 | nothing | categorical |
| order | H-1041 | nothing | an identifier |
| phone number | 19 3255-0000 | nothing | an identifier |

The same test catches the codes that systems invent. A survey that stores "1 = pix, 2 = card, 3 =
cash" has turned a category into digits. Average those codes across the twelve orders and you get
1.67, which a spreadsheet prints to four decimal places and which describes nothing: there is no
payment method two thirds of the way from pix to card. Lesson 2 returns to these coded columns,
because they are where real reports go wrong.

## Identifiers are their own kind

An **identifier** names one observation and nothing else: an order number, a customer number, a
tax number. It is not even a useful category, because every value appears exactly once. Count the
categories and you get as many as there are rows.

Identifiers matter for a different reason: they are how one table is joined to another. Never
average them, never group by them, and never throw them away.

## The one useful exception: yes and no

A **yes/no** variable is categorical, with two categories. Did the order arrive late, yes or no? Was a
voucher used? Code *yes* as 1 and *no* as 0, and something useful happens: **the mean of the column
is the share of yeses**.

Suppose three of Horta's twelve orders arrived after the promised time. Coded 1 for late and 0 for
on time, the column adds up to 3, and its mean is 3 ÷ 12 = 0.25. That 0.25 is a real answer: a
quarter of the orders were late. This trick is the bridge between counting and averaging, and lesson
12 leans on it to build a confidence interval for a proportion.
