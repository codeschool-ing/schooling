---
title: Profiling: measure the data before mapping it
version: 1
---

A data migration looks like a mapping problem: this field goes there, that code becomes this one.
So the first thing most teams write is the mapping, from the old system's documentation and the
new system's data model. **The mapping is the second thing to write. The first is a measurement of
what the old system actually holds**, because the documentation describes what the data was meant
to be, and thirty years of use have made it something else.

That measurement is called **profiling**. It asks plain questions of every table and every field that will move. How many rows, how
many blanks, how many distinct values? Which values repeat where they should be unique, which rows
point at something that does not exist, and which numbers are impossible? None of it needs a tool you have to buy. A copy of the data, SQL and an afternoon with
the person who knows the system will find most of it.

## What Serra Alta is moving

Lesson 13 planned Coleta's retirement as a strangler: one capability at a time moves into the new
farm system, and the old one shrinks. One of those steps is the moment the new system becomes the
master of farms and litres. Lesson 15 asks whether that system should be bought or built; either
way, the data has to move, and this lesson is about moving it.

Two things travel in that step:

- *the farm master*: one record per farm, with its code, the producer's CPF or CNPJ, the
  municipality, the route, the tank, and the number of the farm's vendor record in SAP, which is
  what SAP pays (lesson 1);
- *the collection history*: one row per farm per collection, with the litres and the laboratory
  results that the payment is calculated from. Since 1996 it has grown to about 14.6 million rows.

Joana's first draft of the mapping was written from Coleta's documentation, a binder of record
layouts Sebastião had kept up to date until about 2005. It said the municipality field held a value
chosen from a list. **The profile found 97 different spellings for the 38 municipalities Serra
Alta collects from.** The list had existed on the green-screen form until a change in 2006 made the
field free text, and nobody had updated the binder.

## The questions a profile asks

Joana and Sebastião ran the profile on a copy of Coleta's data, so that nothing they did could
slow the production machine. Coleta's database is Db2 for i, which answers SQL like any other.
The names below are simplified; the real ones are the short, cryptic field names of the RPG era.

```sql
-- how many farms the master holds
SELECT COUNT(*) FROM farm_master;

-- tax ids that appear on more than one farm
SELECT tax_id, COUNT(*) AS farms
FROM farm_master
WHERE TRIM(tax_id) <> ''
GROUP BY tax_id
HAVING COUNT(*) > 1;

-- every spelling of a municipality, most common first
SELECT municipality, COUNT(*) AS farms
FROM farm_master
GROUP BY municipality
ORDER BY farms DESC;

-- collections that point at no farm at all
SELECT COUNT(*)
FROM collection c
WHERE NOT EXISTS (SELECT 1 FROM farm_master f WHERE f.farm_code = c.farm_code);
```

Each query is one of seven questions, and every migration asks all seven of every field that
matters:

| question | what it finds | at Serra Alta |
|---|---|---|
| counts | how big each population is, and what state its rows are in | 2,140 farm records: 1,897 collected from this month, 243 not collected from for more than a year |
| nulls and blanks | fields that should hold something and do not | 17 farms with no CPF or CNPJ, 15 of them among the 243 |
| distinct values | free text where a code was expected | 97 spellings of 38 municipalities; Santos Dumont alone four ways |
| duplicates | one real thing recorded twice | 38 tax ids that appear on two farm records |
| invalid values | values that break a rule of their own | 9 CPFs whose check digits do not add up |
| orphans | rows that point at something that is not there | 1,312 collection rows, from 1998 to 2003, for 6 farm codes deleted from the master |
| outliers | numbers that are possible in the type and impossible in the world | 23 collections more than twenty times the farm's median day |

Two of those rows need the person who knows the system before they mean anything.

**A duplicate tax id is not always a duplicate farm.** Of the 38, 31 are one producer with two
properties, two tanks and two separate payments, which is correct and must stay as two farms. The
other 7 are one tank registered twice, under a new code, when the farm changed hands; collections
were recorded under both codes for a few months. A rule that merged every shared tax id would have
merged 31 producers' farms into one and paid each of them once instead of twice. Sebastião knew
which was which because he had registered most of them.

**An outlier is a question, not an error.** The largest of the 23 is 41,000 litres in one day at a
farm whose median day is 410 and whose tank holds 2,000. That one is two extra zeros typed on a
handheld. Others among the 23 were real: a farm that took in a neighbour's milk for a week while
the neighbour's cooling failed. The profile finds the 23; somebody decides each one.

## Cross-checking against the other systems

Coleta is not the only system that knows about farms. SAP holds a vendor record for each of them,
because SAP is what pays (lesson 1). So the profile also compared Coleta's farm master with SAP's
vendor master, and it found two more things the binder could not have told anybody.

The first was a field nobody owned. **Coleta still holds a bank account for every farm**, from the
years before 2011 when it wrote the payment file itself. Since SAP took over payment, finance has
kept bank details in SAP's vendor master, and nobody has maintained Coleta's copy. For 412 of the
farms the two disagree. Coleta's field is not even in one format: older records hold the agency and
the account in a single field with dashes, newer ones in two fields.

The second was a link gone stale: four farms carry the number of an SAP vendor that finance has
blocked, because the farm's payments moved to a new vendor record after a change of owner and
Coleta was never told.

## Scope is a finding too

Moving everything is the default nobody chooses on purpose. Finance and the legal team set Serra
Alta's rule for what the new system must hold: **the current year and the five before it**. Older
history goes to an archive that can be searched and never changed (the last section of this lesson
is about it).

The profile turned that sentence into numbers. **1,958 farms have at least one collection inside
the period**, so they move; 182 have none, so they go to the archive only. Of the 14.6 million
collection rows, about 4.1 million fall inside the period. The 1,312 orphans are all from before
2004 and go to the archive with a note saying what they are.

Those numbers do two jobs. They size every later step, from how long a load takes to how many
farms Cláudia's team has to look at by hand. And they are what the reconciliation later in this
lesson will be measured against: 1,958 farms is the number that has to arrive, less the duplicates
that are merged on purpose.

## Why now and not later

A surprise found in a profile costs a meeting. The same surprise found during a rehearsal costs a
rehearsal, and found on the cutover night it costs the night. **Every finding in the table above
would have arrived anyway**; the profile only decides when.

The free-text municipalities would have failed the load, because the new system stores the
municipality as its IBGE code. The 31 legitimate shared tax ids would have failed it too, if
anybody had added a unique constraint on tax id because the binder implied one. The stale bank
accounts would not have failed anything: they would have loaded perfectly, and the first farm paid
into a closed account would have found them.

That last kind is the reason to profile fields nobody intends to use. **A load fails loudly on a
value that breaks a rule, and silently on a value that is wrong and well formed.** Only the
measurement, done before anybody wrote a rule, finds the second kind early.

Profiling is also not a one-off. Coleta keeps running while the new system is built, and its data
keeps changing; Joana's team re-ran the same queries before each rehearsal and compared the results
with the last run. A count that moves by a few farms is the business. A count that moves by two
hundred is a new problem, and the earlier it is noticed the cheaper it is.
