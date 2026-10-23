---
title: Interface contracts and how they change
version: 1
---

**An interface contract is everything the consumer of an integration relies on, written down where
both sides can read it.** The usual belief is that the contract is the schema: a WSDL, an OpenAPI
file, a record layout. The schema is one line of it. Most of the integrations that broke at Serra
Alta in the last five years broke with the schema untouched. A file arrived two hours later than usual. A field changed
its meaning. One side reported an error and the other side ignored it.

## What a contract states

Joana's template has seven parts. Here they are for the oldest integration in the company, Coleta's nightly file to SAP. It had none of them written down until she asked Sebastião and Edson to sit in one room:

| part | the question it answers | Coleta's file to SAP |
|---|---|---|
| schema | what the data looks like | the fixed-width layout with its header and trailer (lesson 9 shows it) |
| semantics | what each field means | litres as measured at the farm tank; fat and protein in grams per 100 g; the date is the day of collection, not of loading |
| volumes | how much, normally and at worst | about 1,900 lines a night, up to about 2,100 at the rainy-season peak |
| timing | when it arrives and when it is needed | in the directory by 01:30; loaded by 02:30, or by 06:30 on Sundays |
| error behaviour | what happens to bad data | a line that fails validation goes to a reject file sent back to Coleta; the rest of the file loads |
| owners | who answers for each side | Sebastião for Coleta, Edson for the load in SAP |
| version | which agreement this is | version 1, the first one anybody wrote |

**Semantics and timing are where contracts break silently.** A schema change makes the receiver
fail loudly, which is the good case. A change of meaning passes every check. If Coleta began
sending the date of loading instead of the date of collection, every line would still parse, and
every farm's milk from Saturday would be paid as Sunday's.

## Compatible and breaking changes

A change to an interface is **compatible** if every existing consumer keeps working without
changing anything, and **breaking** if at least one has to change. Whether a change breaks depends
less on the change than on how the consumers read, and that is the part that surprises people.

| change | compatible? |
|---|---|
| a new optional field in a JSON message | yes, for consumers that ignore what they do not know |
| a new field at the end of a fixed-width line | no, for any loader that checks the length of each line, as SAP's does |
| a field renamed | no |
| a unit changed under the same name, litres to kilograms | no, and nothing fails: the worst kind |
| a numeric field widened from 9 to 11 digits in a fixed-width record | no: every field after it moves |
| a new value in a list of codes, a new quality grade | no, for any consumer that maps every code it knows and rejects the rest |
| the file arriving two hours later | no, for a load that runs at 02:00 |

The first two rows are the same change in different formats. JSON consumers can be written to
ignore fields they do not recognise, and Martin Fowler's name for a consumer written that way is a
*tolerant reader* (2011): read only what you need, and let the rest go by. **A tolerant reader turns
many breaking changes into compatible ones**, and it is the cheapest thing a consumer can do for its
own future. A fixed-width loader cannot be tolerant in the same way, because position is meaning:
it has no way to tell an extra field from a shifted one.

## Versions and deprecation

A breaking change goes out as a **new version beside the old one**, never as an edit to the old one.
The consumers move when they can, and the old version is switched off when the last one has moved.

That last sentence is where policy is needed, because otherwise the old version lives for ever.
Joana's rule:

- a new version is announced in the registry with its date and its differences;
- the old version stays for six months after the new one is available, and the registry shows
  which consumers are still on it;
- the consumers still on it are told on the day of release, at three months and at one month;
- the old version is switched off when its traffic, measured and not assumed, has been zero for a
  month, or at six months with the owners of any remaining consumer agreeing the date.

Version numbers follow the habit of semantic versioning: the major number moves on a breaking
change, the minor on a compatible one. For a web service the major version goes in the address
(`/v2/`), so that both can run at once. For a file it goes in the header, so that the reader can
refuse a version it does not understand rather than misreading it.

## Consumer-driven contracts

A producer cannot know which of its fields matter. It can know what it publishes; it cannot know
that the portal reads `available` and ignores `reserved`, while Rota reads both. Ian Robinson's
article *Consumer-Driven Contracts* (2006) turned that around: **each consumer states what it
relies on, as tests, and the producer runs every consumer's tests before releasing.** A change that
breaks a consumer fails the producer's build instead of the consumer's morning.

Pact is the best-known tool for it. The consumer's test records the requests it makes and the parts
of each answer it depends on; the record is published; the producer's build replays it against the
real service. Serra Alta's own systems, the Portal B2B and Rota, can work this way, because both
sides are teams in the same company with builds they control.

It does not reach SAP or Salesforce. Neither vendor will run Serra Alta's tests before a release. For
those, the same idea runs the other way round: Serra Alta keeps tests of what it relies on in their
interfaces, and runs them against the vendor's sandbox before each upgrade reaches production. It is
not a contract the vendor has signed, but it finds the breaking change in a test environment, which
is where it should be found.

## The registry

Lesson 9 left Joana with a map of about 110 integrations. She turned it into a registry, one entry per integration in the shape of the table above, and it showed how little was written down: 39 had any
specification at all, most of them the bus flows' WSDLs, and 14 had a named owner on both sides.

She did not try to fill all 110 at once. The first entries were the 23 integrations that move
money, tax documents or the trucks. Every new integration gets an entry before it goes to
production, and every change to an existing one fills in its entry if it has none. An entry is
short and kept in a repository, so that a change to a contract is a change somebody reviews:

```yaml
id: int-coleta-sap-receipts
producer: Coleta
consumer: SAP ECC (goods receipts of milk)
style: file
version: 1
owners:
  producer: Sebastião Lima
  consumer: Edson Prado
schema: lesson 9 layout, header and trailer with record count and total litres
semantics: litres measured at the farm tank; date is the day of collection
volume: about 1900 lines a night, peak about 2100
timing: file by 01:30; loaded by 02:30, Sundays by 06:30
window: SAP down Sundays 01:00-05:00
errors: rejected lines returned to Coleta in a reject file; the rest loads
objective: loaded by 06:30 on 99% of days in a rolling 90 days
```

The last line connects this section to the second one. **A contract without an objective says what
crosses and not how well**, and an objective without a contract measures something nobody agreed
on. The registry is where the two meet, with the calendar beside it.
