---
title: Two clocks for one breach
version: 1
---

**Article 33** of the GDPR: in the case of a personal data breach, the controller notifies the
supervisory authority **without undue delay and, where feasible, not later than 72 hours** after
becoming aware of it — unless the breach is **unlikely to result in a risk** to people. A notice later
than 72 hours carries the reasons for the delay. Information not yet known may be provided **in
phases**. **Article 34** adds the people themselves, without undue delay, when the risk to them is
**high**. And article 33(5) asks for every breach to be documented, notified or not.

Lesson 7 set the Brazilian rule beside it: three working days for the ANPD and for the people, twenty
more to complete, five years of records. The shapes match. The clocks do not, because **72 hours are
hours** — Saturday counts, a holiday counts — and three working days are not.

## Computing both

A breach that touches the Lisbon customers is a breach under both laws, with both clocks running from
the same moment. Ipê works the deadlines out in the database rather than on a calendar:

```sql
-- Two deadlines for one incident: the GDPR's 72 hours, which run through
-- weekends and holidays, and the ANPD's three working days, which do not.
-- The twenty days to complete the information count from the notice.
SET ROLE ipe_owner;
CREATE TABLE gov.holidays (day date PRIMARY KEY, name text NOT NULL);
-- National holidays only. A state or city holiday where the company sits
-- is a row somebody has to add.
INSERT INTO gov.holidays VALUES
 ('2026-01-01', 'Confraternização Universal'), ('2026-04-21', 'Tiradentes'),
 ('2026-05-01', 'Dia do Trabalho'),            ('2026-09-07', 'Independência'),
 ('2026-10-12', 'Nossa Senhora Aparecida'),    ('2026-11-02', 'Finados'),
 ('2026-11-15', 'Proclamação da República'),   ('2026-11-20', 'Consciência Negra'),
 ('2026-12-25', 'Natal');
INSERT INTO gov.column_class VALUES
 ('gov','holidays','day','none','a date in the calendar'),
 ('gov','holidays','name','none','its name');

-- The n-th working day after the day something became known.
CREATE FUNCTION gov.working_day(known timestamptz, n integer) RETURNS date
LANGUAGE sql STABLE AS $$
  SELECT d::date
  FROM generate_series(known::date + 1, known::date + 60, interval '1 day') AS d
  WHERE extract(isodow FROM d) < 6
    AND d::date NOT IN (SELECT day FROM gov.holidays)
  ORDER BY d
  OFFSET n - 1 LIMIT 1
$$;

SELECT to_char(k, 'Dy DD Mon HH24:MI')                          AS known,
       to_char(k + interval '72 hours', 'Dy DD Mon HH24:MI')    AS gdpr_72h,
       to_char(gov.working_day(k, 3), 'Dy DD Mon')               AS anpd_3_working_days,
       to_char(gov.working_day(gov.working_day(k, 3), 20), 'Dy DD Mon') AS anpd_complete_20
FROM (VALUES (timestamptz '2026-04-17 18:00-03')) AS v(k);
```

```
ana@lab:~/gov$ psql -f clock.sql
SET
CREATE TABLE
INSERT 0 9
INSERT 0 2
CREATE FUNCTION
      known       |     gdpr_72h     | anpd_3_working_days | anpd_complete_20 
------------------+------------------+---------------------+------------------
 Fri 17 Apr 18:00 | Mon 20 Apr 18:00 | Thu 23 Apr          | Fri 22 May
(1 row)
```

The breach becomes known on a **Friday evening**, 17 April 2026. The CNPD has to hear by **Monday at
18:00**. The ANPD's third working day skips the weekend and **Tiradentes** on Tuesday 21 April, and
lands on **Thursday 23**. The information is complete by **22 May**, twenty working days after the
notice.

Two things are worth taking from those four columns:

- **The European deadline is the binding one here, by three days.** A team that plans for "three days"
  because that is the number it knows from Brazil has missed the CNPD's by the time it sends the
  ANPD's. When one incident is under two laws, the response plan works to the earlier clock.
- **The holiday table is part of the rule.** It holds national holidays only, and the comment says so.
  A breach known on the day before a state holiday in São Paulo gets one day more than this function
  gives, which errs on the safe side; one known before a holiday the table lists wrongly gets one day
  less than the law, which does not. A calendar that decides a legal deadline is data somebody owns,
  with a person whose job it is to fill in next year's.

## Why "where feasible" is not a reprieve

Both laws accept a first notice that does not yet know everything. That is the point: the clock is for
**telling**, not for **finishing**. A first notice on Monday that says what is known — which systems,
roughly how many people, what was done to stop it — and says plainly what is not yet known, meets
article 33. A complete report on Thursday does not, however good it is.
