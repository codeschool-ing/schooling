---
title: Durability and availability are two promises
version: 1
---

"Eleven nines" gets quoted as though it meant an object store cannot fail. It is a figure about one
of two things, and the two are easy to run together.

**Durability is whether the bytes still exist.** S3 Standard is designed for 99.999999999% durability
over a year. AWS illustrates it with ten million objects: 10,000,000 × 0.00000000001 = 0.0001
objects lost a year, which is one object every ten thousand years.

**Availability is whether you can read them now.** S3 Standard is designed for 99.99% availability.
A year has 525,600 minutes, and 0.01% of them is about 53 minutes in which requests may fail. The
data is not lost during those minutes; it is out of reach.

| | the question | S3 Standard, designed for | what it looks like when it fails |
|---|---|---|---|
| durability | will the bytes survive? | 99.999999999% a year | an object is gone for good |
| availability | can I read them right now? | 99.99% | requests fail, then work again |

Both come from the same mechanism. **Standard keeps every object on devices in at least three zones
of the region**, so a failed disk, a failed rack or a whole zone going dark loses nothing, and the
other zones keep answering. Take the replicas away and both figures fall. S3 One Zone-Infrequent
Access keeps data in a single zone to charge less: it is designed for 99.5% availability, and the
data in it is lost if that zone is destroyed. It suits data you could make again, such as thumbnails
generated from originals kept elsewhere.

A block volume sits lower on both scales. It is replicated only inside its zone, and AWS states its
durability for `gp3` as an annual failure rate of 0.1 to 0.2 percent, which is one volume in every
five hundred to a thousand failing in a year. That gap is why a volume has snapshots and an object in
Standard does not need copies against hardware failure.

## What eleven nines does not cover

**Durability is the store keeping what you told it to keep.** It is measured against disks and
buildings failing, and it says nothing about the requests you send. When a cleanup script deletes the
wrong prefix, when a deploy overwrites a config with an empty file, or when an attacker holding a
leaked key encrypts every object in place, the store keeps the result with eleven nines of care.

The protections against that are different mechanisms, and each costs something:

- **Versioning**, the next section, keeps the old version when an object is overwritten or deleted.
- **Replication** to a bucket in another region, and better another account, keeps a copy that the
  credentials of the first account cannot reach.
- **Object lock** makes versions undeletable for a period, even by an administrator. It is the
  answer to the attacker case, and `cloud-security` covers it with the rest of that defence.
