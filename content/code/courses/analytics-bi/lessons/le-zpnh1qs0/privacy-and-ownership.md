---
title: Personal data, and who owns the fields
version: 1
---

Reverse ETL copies data out of the warehouse into tools other people run. Two questions have to be
answered before the first sync, and neither is technical.

## Personal data leaves the building

Lantern's model sends no names and no e-mail addresses: a customer id, a segment, a region and some
numbers. A real CRM sync almost always sends more, and each field is personal data being copied to a
company that runs the CRM. Under the LGPD that copy needs the same things the source needed:

- **a purpose**: the field exists in the CRM because somebody acts on it. That is also this lesson's
  second section, from the other side;
- **minimisation**: send the fields the purpose needs, and nothing because it is available;
- **a contract with the vendor** that processes the data on the company's behalf, saying what it may
  and may not do with it;
- **erasure that reaches the copy**, which the delete loop of this lesson is.

A sync is the easiest way there is to put a lot of personal data in a lot of places, quietly. That is
the reason to treat its model as a decision somebody signs.

## Who owns a field

The sync writes `health` on every contact, every hour. A salesperson who changes it by hand, because
they know something the data does not, sees their change undone at the next run, and stops trusting the
CRM. **Every synced field needs one owner**: either the sync — then the field is read-only for people,
and the CRM says so — or people — then the sync does not write it. A field both write is a field nobody
can rely on.

The same rule applies to the sync itself. It needs an owner, like a dashboard in lesson 6: the person
who reads its last line, answers when a salesperson reports a wrong value, and decides when the model
changes. Lesson 8 shows how the commercial tools organise exactly these decisions.
