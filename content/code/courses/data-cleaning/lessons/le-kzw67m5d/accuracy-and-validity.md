---
title: Accuracy and validity: right, and well-formed
version: 1
---

**Accuracy asks whether a value matches the world. Validity asks only whether it is the kind of
value the column allows.** The two are easy to confuse because the second is so much easier to
check, and a check that is easy tends to get mistaken for the one that matters.

A birth year of `1987` is valid: four digits, inside a plausible range. It is accurate only if
the customer was born in 1987, and nothing in the file can tell you that. A birth year of `87` is
**invalid** — the column is supposed to hold years and this is not one — but it may well be
accurate, since the person who typed it almost certainly meant 1987.

Ana asks the column what it holds most often:

```
ana@lab:~/clean$ psql -c "SELECT birth_year, count(*) FROM raw.customers GROUP BY birth_year ORDER BY count(*) DESC LIMIT 4"
 birth_year | count 
------------+-------
 1900       |   348
            |   338
 1975       |    41
 2005       |    38
(4 rows)
```

The most common birth year among Quitanda Verde's customers is 1900. That is valid, well-formed,
inside any range a rule would set for a year — and false for all 348 of them. Nobody alive was
born in 1900. It is **a placeholder**: a form that would not save without a year, and staff who
typed the first one that worked.

Splitting by where the customer signed up shows where each defect is born:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, count(*) FILTER (WHERE birth_year = '1900') AS year_1900, count(*) FILTER (WHERE length(birth_year) = 2) AS two_digits FROM raw.customers GROUP BY signup_channel ORDER BY signup_channel"
 signup_channel | year_1900 | two_digits 
----------------+-----------+------------
 app            |         0 |        103
 import-2023    |         4 |          3
 site           |         0 |          0
 store          |       344 |          0
(4 rows)
```

Every two-digit year came from the app, and almost every 1900 came from the shops. **A defect
almost always has one source**, and finding the source turns a cleaning rule into a question
somebody can answer: the shops' form needs a year it should not demand, and the app stores what
the person typed without padding it to four digits.

What one placeholder does to a summary is easy to measure. The average age of the customers
whose year has four digits, with and without it:

```
ana@lab:~/clean$ psql -c "SELECT round(avg(2025 - birth_year::int), 1) AS with_1900, round(avg(2025 - birth_year::int) FILTER (WHERE birth_year <> '1900'), 1) AS without_1900 FROM raw.customers WHERE length(birth_year) = 4"
 with_1900 | without_1900 
-----------+--------------
      59.3 |         45.2
(1 row)
```

Fourteen years older on average, from one value typed to get past a form. **Nothing failed**: the
conversion worked, the average is a number, and a report built on it would have told marketing
that its customers are on the edge of sixty.

## Why the difference matters

| | invalid | valid and inaccurate |
|---|---|---|
| example | `87` | `1900` |
| can a rule find it? | yes: the format is wrong | only if the rule knows the placeholder |
| what fixing it needs | a decision about what was meant | information from outside the file |
| what happens if ignored | a conversion fails, or reads it as year 87 | an average that looks fine and is not |

Invalid values announce themselves, at least to anybody who converts the column; lesson 10 is
about converting safely. **Inaccurate values that are valid say nothing**, and the only defences
are knowing the domain — nobody here was born in 1900 — and comparing with a second source. For a
birth year the second source is the customer, which is why accuracy is the most expensive
dimension to measure and the one most often skipped.

A practical consequence: an accuracy rule is always a statement about the world written in the
language of the data. "A birth year is not 1900" is a rule about this company's form, not a law
of nature, and the scorecard at the end of this lesson writes it exactly like that.
