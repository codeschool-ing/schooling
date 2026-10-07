---
title: Columns that identify together
version: 1
---

Take the CPF, the name and the e-mail out of a dataset and the obvious identifiers are gone. What is
left are columns that identify nobody on their own and, together, often identify one person exactly.
They are called **quasi-identifiers**: date of birth, sex, postcode, city, profession, the date of an
event.

The question to ask of any release is not "does it contain identifiers?" but **"how many people are
alone in their group?"** — alone meaning nobody else in the data shares their values of the
quasi-identifiers. A person alone in their group can be singled out by anybody who knows those few
facts about them, which neighbours, colleagues and data brokers do.

Ipê's customers, measured for three choices of what a release might carry:

```sql
-- How many customers are alone in their group, for three choices of what
-- an export carries about them. The rest of the columns are not the point.
SET ROLE ipe_owner;
WITH c AS (SELECT * FROM sales.customers)
SELECT 'birth date, sex, CEP' AS released,
       count(*) FILTER (WHERE n = 1) AS alone, count(*) AS customers
FROM (SELECT count(*) OVER (PARTITION BY birth_date, sex, cep) AS n FROM c) g
UNION ALL
SELECT 'birth year, sex, city',
       count(*) FILTER (WHERE n = 1), count(*)
FROM (SELECT count(*) OVER (PARTITION BY extract(year FROM birth_date), sex, city) AS n FROM c) g
UNION ALL
SELECT 'decade of birth, sex, state',
       count(*) FILTER (WHERE n = 1), count(*)
FROM (SELECT count(*) OVER (PARTITION BY extract(decade FROM birth_date), sex, state) AS n FROM c) g;
```

```
ana@lab:~/gov$ psql -f quasi.sql
SET
          released           | alone | customers 
-----------------------------+-------+-----------
 birth date, sex, CEP        |  5988 |      6012
 birth year, sex, city       |   670 |      6012
 decade of birth, sex, state |    22 |      6012
(3 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l5-kanon\" aria-label=\"Three releases of the same 6,012 customers and how many are alone in their group. Birth date, sex and CEP: 5,988 alone. Birth year, sex and city: 670. Decade of birth, sex and state: 22.\"><text x=\"218.0\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">birth date, sex, CEP</text><rect x=\"230.0\" y=\"40.0\" width=\"410.0\" height=\"32.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"230.0\" y=\"40.0\" width=\"408.4\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.4\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">5,988</text><text x=\"218.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">birth year, sex, city</text><rect x=\"230.0\" y=\"98.0\" width=\"410.0\" height=\"32.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"230.0\" y=\"98.0\" width=\"45.7\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"283.7\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">670</text><text x=\"218.0\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decade, sex, state</text><rect x=\"230.0\" y=\"156.0\" width=\"410.0\" height=\"32.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"230.0\" y=\"156.0\" width=\"2.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">22</text><text x=\"640.0\" y=\"215.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">of 6,012 customers, alone in their group</text></svg>", "caption": "Coarser quasi-identifiers, fewer people alone, and still not none."}
```

The three lines are three releases of the same customers:

- **birth date, sex and CEP**: 5,988 of 6,012 customers are alone. Ipê's CEPs in the lab are close to
  unique on their own, as real eight-digit CEPs often are for a street; a release with those three
  columns is a list of named people with the names removed.
- **birth year, sex and city**: 670 still alone. Coarser, and more than one customer in ten is
  still the only one of their kind.
- **decade of birth, sex and state**: 22 alone. Much better, and not zero.

**Nothing in any of the three releases is an identifier.** That is the point: the danger is in the
combination, and it only shows when somebody measures it. A quasi-identifier is also only
dangerous *as published*; Ipê's own database holds all of them for good reasons, under the grants of
lessons 1 and 2.

## What a reader of a release knows

Measuring needs one more decision: **which columns would an outsider know?** Birth date, sex and
postcode are on many documents and in many leaked databases. Which medicines somebody bought are not
— which is exactly why they are the sensitive part, and why they are the column a release exists to
publish. The quasi-identifiers are what has to be coarsened; the sensitive value is what everybody is
trying to protect.
