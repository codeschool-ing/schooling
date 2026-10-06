---
title: The question a schema cannot answer
version: 1
---

Ana's model has twelve tables and 92 columns, every one with a name and a type. `net_cents BIGINT` says the
column holds a whole number and that somebody thought of it as cents. It does not say whether shipping is in it,
whether discounts were taken off, whether a cancelled order counts, or which day a sale belongs to. Those are the
questions people actually ask, and **the schema answers none of them**.

Lesson 11 showed what that costs. Three marts, three meanings of "revenue", a meeting that spent its hour on whose
number was right, and a defect, every shop's sales missing from marketing's figure, that nobody had seen because
nobody had compared the definitions. Each definition was in somebody's head, or in SQL only its author read.

The remedy is old and unglamorous: **write down what each column means, next to the column, and keep it true**. The
written list is called a **data dictionary** or field dictionary. At the scale of one warehouse it is a document; at
the scale of a company it becomes a **data catalogue**, a searchable service over every dataset, with owners and
lineage. This lesson builds the first and shows how it grows into the second.

The dictionary is also where two obligations meet that look unrelated. One is analytical: a number nobody can
explain is a number nobody should act on. The other is legal: Brazil's data protection law asks a company to know
what personal data it holds and where, and **a dictionary that classifies each column is the place that answer
lives**. Sections 9 and 10 come to that.
