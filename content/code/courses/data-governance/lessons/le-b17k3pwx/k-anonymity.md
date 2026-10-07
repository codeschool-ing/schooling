---
title: k-anonymity, and what it does not promise
version: 1
---

The last section counted people alone in their group. **k-anonymity** turns that into a rule: a
release is *k*-anonymous if every combination of quasi-identifiers in it is shared by at least *k*
people. With *k* = 5, anybody trying to single somebody out lands in a crowd of at least five.

The coarsest of the three releases, measured against *k* = 5:

```sql
-- The smallest group, and how many groups are smaller than k = 5, for the
-- generalised release: decade of birth, sex and state.
SET ROLE ipe_owner;
SELECT min(n) AS smallest_group,
       count(*) FILTER (WHERE n < 5) AS groups_under_5,
       sum(n) FILTER (WHERE n < 5) AS customers_in_them,
       count(*) AS groups
FROM (SELECT count(*) AS n FROM sales.customers
      GROUP BY extract(decade FROM birth_date), sex, state) g;
```

```
ana@lab:~/gov$ psql -f kanon.sql
SET
 smallest_group | groups_under_5 | customers_in_them | groups 
----------------+----------------+-------------------+--------
              1 |             61 |               132 |    246
(1 row)
```

**246 groups, and 61 of them have fewer than five people** — 132 customers in groups too small. The
smallest group has one. So "decade of birth, sex and state", which looked safe at 22 people alone, is
not 5-anonymous. Two moves get there, and both lose information:

- **generalise further**: region instead of state, a wider age band — fewer, larger groups;
- **suppress**: leave the 132 customers out of the release, or blank their quasi-identifiers, and say
  in the release that small groups were suppressed.

Which one is right depends on what the release is for. A study of regional differences cannot lose
the state; a study of age effects cannot lose the age.

## What k-anonymity does not promise

**A crowd of five who all bought the same medicine reveals that medicine for all five.** If every
customer in the group "born in the 1970s, female, Rio Grande do Norte" has a psychiatric
prescription, knowing a
woman from Rio Grande do Norte born in the 1970s is in the release tells you her diagnosis, though
you cannot tell
which row is hers. That weakness is old and well known, and the refinements named after it —
*l*-diversity, *t*-closeness — ask that the sensitive values inside each group be varied as well.

**And it says nothing about combining releases.** Two releases, each 5-anonymous, can single a
person out when joined, if they generalise differently. A team that publishes more than once has to
measure what the releases say together.

The defensible use of *k*-anonymity is as **a measurement and a floor**, not as a certificate: a
release with groups of one is certainly unsafe, and a release where every group has five people is
safer, by a margin the next section turns into a rule for counts.
