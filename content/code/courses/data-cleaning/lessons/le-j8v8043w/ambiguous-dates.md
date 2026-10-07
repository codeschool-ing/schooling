---
title: Ambiguous dates, and how to prove which is which
version: 1
---

**`03/04/2025` is the 3rd of April in Brazil and the 4th of March in the United States**, and nothing
in the string says which country wrote it. A parser that guesses will guess one way for every row,
and be wrong for every row from the other source:

```
ana@lab:~/clean$ python -c "import pandas as pd; print(pd.to_datetime('03/04/2025'), pd.to_datetime('03/04/2025', dayfirst=True))"
2025-03-04 00:00:00 2025-04-03 00:00:00
```

pandas reads it month first unless told otherwise, and day first when told. Both are valid dates.
**A wrong reading of a date produces another valid date**, which is why this defect survives so
long: nothing fails, and every chart by month quietly moves a twelfth of the year to the wrong month.

Lesson 1 found three conventions in `signed_up`: ISO from the website, day first from the shops,
month first from the app. A claim like that should be proved, not assumed, and the data can prove
it: **a day can exceed 12 and a month cannot.** Counting, for each source, how often the first and
the second number pass 12:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, count(*) FILTER (WHERE split_part(signed_up, '/', 1)::int > 12) AS first_over_12, count(*) FILTER (WHERE split_part(signed_up, '/', 2)::int > 12) AS second_over_12 FROM raw.customers WHERE signed_up LIKE '%/%' GROUP BY 1"
 signup_channel | first_over_12 | second_over_12 
----------------+---------------+----------------
 app            |             0 |            438
 import-2023    |             3 |              8
 store          |           380 |              0
(3 rows)
```

The shops have 380 values whose first number is above 12 and none whose second is: day first,
proved. The app has the reverse, 438 and 0: month first, proved. Every value with a number above 12
is a witness, and with hundreds of witnesses and no exception the convention is not in doubt.

**The 2023 migration has both kinds of witness**: 3 values with the first number above 12 and 8 with
the second. It copied records from all three systems without converting them, so its column mixes
conventions within one source. That changes how it has to be parsed, and the next section shows
how.

The same test settles any ambiguous date column: count the witnesses on each side. If one side has
none, the convention is clear. If both have some, the column mixes conventions, and each value needs
something else to decide it — its source, its neighbours, or a person.
