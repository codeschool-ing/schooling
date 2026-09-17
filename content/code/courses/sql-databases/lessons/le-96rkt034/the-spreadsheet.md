---
title: Where everybody starts, and where it stops
version: 1
---

Nearly every database in the world began as a spreadsheet, and most of them worked. That is worth
saying before anything else, because the relational model is usually taught as though the
spreadsheet were a mistake. It is not a mistake. It is the right tool until a specific day, and
learning to recognise that day is most of what this lesson is for.

Here is a real one. A small shop keeps its orders in a single sheet:

| order | date | customer | email | city | item | qty | unit price |
|---|---|---|---|---|---|---|---|
| 1001 | 2026-03-02 | Ana Lopes | ana@example.com | Porto | Kettle | 1 | 34.90 |
| 1002 | 2026-03-02 | Bruno Sá | bruno@example.com | Lisboa | Kettle | 2 | 34.90 |
| 1003 | 2026-03-04 | Ana Lopes | ana@example.com | Porto | Toaster | 1 | 51.00 |
| 1004 | 2026-03-07 | Ana Lopes | ana@exmaple.com | Porto | Kettle | 1 | 34.90 |

Four rows. Everything a person needs is on the row in front of them, which is exactly why this
shape is so appealing — you read one line and you know the whole story.

Look at row 1004.

## The same fact, written down more than once

`ana@exmaple.com`. The `a` and the `m` are the wrong way round, and it happened because a human
typed the address for the third time. Nobody typed it wrong on purpose; they typed it wrong
because they were asked to type it at all.

**The sheet has three copies of Ana's email address and no opinion about which is correct.** It
cannot have one. Each row is a separate statement, and the sheet was never told that the three
rows are about the same person. As far as it is concerned, `ana@example.com` and
`ana@exmaple.com` are two strings that happen to look similar.

This is the failure the whole rest of this course is organised around, so it is worth naming
precisely. It is not "there is a typo". Typos are unavoidable. It is that **the sheet cannot tell
you there is one**, because it holds no record of what a customer is — only of what each row says.

Now consider the ordinary consequences:

- Ana moves to Braga. You must find every row that is hers and change the city on each one. Miss
  one and she now lives in two places.
- Ana's email is corrected on row 1004 but not on 1003. Which is right? Nothing in the file
  answers this.
- You want to email every customer once. There is no list of customers. There is a list of
  *orders*, and you have to guess that two rows are one person by comparing text.

Each of these is the same defect wearing a different coat: **one fact is stored in many places, so
the places can disagree.**

## And the question it cannot answer

The defect above is about writing. There is a second one, about reading, and it is the one that
usually decides the matter.

> Which customers ordered at least twice in March and have not ordered since?

Read the sheet again and try to see the shape of that answer. You need to group rows by customer —
but "customer" is a piece of text, so you are grouping by whether two strings match, and row 1004
will fall out of the group because of one transposed letter. Then you need the *absence* of later
rows, which is not a thing you can see by looking at rows that are present.

A spreadsheet answers **questions somebody planned for**. You can add a column, write a formula,
build a pivot table — and each of those is a person deciding, in advance, that this question
matters. The answer exists because somebody built it.

**A database answers questions nobody planned for.** That is not a difference of degree. It is the
entire point, and it is bought with exactly one idea.

## The one idea

> Every fact is written down once, in one place, and everything that needs it points at it.

Ana is recorded once, as a customer. Her orders do not contain her name, her email or her city;
they contain a pointer to her. Correct her email in the one place it lives, and every order she
has ever placed is now correct, because none of them held a copy in the first place.

That is the relational model. Everything else in this lesson — keys, foreign keys, constraints,
the `NULL` that catches everybody — is machinery for making that one sentence work.

## Two honest limits

**This is not free.** The four-row sheet above becomes three tables, and reading one order now
means looking in three places instead of one. For four rows that is plainly worse. The trade only
pays when the data outlives the person who entered it, when more than one person writes to it, or
when somebody will ask a question you have not thought of yet. If none of those is true, the
spreadsheet is the correct tool and using a database is showing off.

**And the relational model is not the only one.** There are document stores, graph databases,
key-value stores and columnar warehouses, each good at something this is not. They are a later
course. What makes this one the place to start is that the relational model is the oldest, the
most widely deployed, and the one whose ideas the others are usually explained *against*.
