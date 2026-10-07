---
title: Writing down where it came from
version: 1
---

A reference table that arrived without a note is a liability: a year later nobody knows whether it
was official, how old it is or whether it may be shared. So this lesson writes a small file by hand
beside the references, one row per source:

```
file,publisher,document,obtained,valid_for,terms
ref/ibge_states.csv,IBGE,codes of the 27 federative units,typed from the published list,stable since 1988,public data; cite IBGE
ref/ibge_cities.csv,IBGE,7-digit municipal codes,typed from the published list,stable; a new municipality gets a new code,public data; cite IBGE
ref/holidays_2025.csv,federal government,holiday laws and the 2025 calendar of optional days,typed from the published calendar,2025 only,laws are not subject to copyright
```

Each column answers one of the four questions from the first section, and each has a reason to be
there:

- **`publisher` and `document`** say who stands behind the values. The state and city codes are
  IBGE's, the national statistics office, which is the authority on them. The holidays come from the
  federal laws that create them and from the federal government's calendar for the year, which also
  lists the optional days.
- **`obtained`** says how the file got here. Here the values were typed in from the
  published lists, which is honest and weaker than a download: a typed value can carry a typo, and
  only a comparison with the source would show it.
- **`valid_for`** says when the values hold. Holidays are the clearest case: 20 November, Black
  Awareness Day, became a national holiday only from 2024, by Law 14.759 of 2023. A holiday list from
  2023 would mark the shops' closure that day as missing data.
- **`terms`** says what you may do with it. Public data from a government source is generally free
  to use with the source cited, but "generally" is the reason to read the terms of the actual
  source rather than assume them.

**The sources file is part of the analysis**, as much as the code. It travels with the results, it
is what a reviewer reads first, and it is what lesson 17 will put under version control beside the
scripts.
