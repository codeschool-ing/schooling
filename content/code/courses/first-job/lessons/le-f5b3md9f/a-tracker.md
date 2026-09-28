---
title: A tracker
version: 1
---

The tracker is a spreadsheet, or a CSV file, with one row per application and six columns: **the date, the
company, the role, where you found it, the stage it has reached, and the next thing to do**. Here is the
top of the invented one:

```
$ head -4 applications.csv
date,company,role,source,stage,next
2026-06-01,Colégio Horizonte,Suporte N1,site,rejected,
2026-06-01,Rede Saúde Sul,Service desk júnior,LinkedIn,screening,call 06-15
2026-06-02,TecnoAlocação,Suporte júnior (alocado),LinkedIn,applied,follow up 06-09
```

Because it is plain data, it answers questions. How many applications are at each stage:

```
$ cut -d, -f5 applications.csv | tail -n +2 | sort | uniq -c | sort -rn
      6 applied
      2 screening
      2 rejected
      1 offer
      1 interview
```

Which source leads anywhere. In this file the three referrals all moved on and none of the five
applications through careers sites did:

```
$ awk -F, 'NR > 1 { n[$4]++; if ($5 != "applied" && $5 != "rejected") r[$4]++ } END { for (s in n) printf "%-9s %2d sent, %d moved on\n", s, n[s], r[s] }' applications.csv | sort
LinkedIn   4 sent, 1 moved on
referral   3 sent, 3 moved on
site       5 sent, 0 moved on
```

One invented file proves nothing about the market. It shows **what the tracker is for**: after a month of
your own search, the same question about your own rows tells you where to spend the next month. Lesson 9 is
about referrals, and whether they work for you is something your tracker can answer.

The last column is the one that makes it a tool rather than a record. Each application that is waiting has
a date for the follow-up (lesson 10), and once a week the tracker tells you whom to write to:

```
$ awk -F, 'NR > 1 && $6 ~ /follow up/ { print $6 " — " $2 }' applications.csv | sort
follow up 06-09 — TecnoAlocação
follow up 06-10 — Fintech Aurora
follow up 06-12 — Hospital Central
follow up 06-15 — Agência Pixel
follow up 06-15 — Distribuidora Leste
```
