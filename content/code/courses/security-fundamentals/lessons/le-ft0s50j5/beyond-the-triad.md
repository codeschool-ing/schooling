---
title: Beyond the triad
version: 1
---

The triad is the core, and it is not the whole vocabulary. Four more words turn up constantly,
and each one answers a question the three letters leave open.

**Authenticity** is knowing that information really came from where it claims. An email "from the
bank" that is not from the bank fails on authenticity even if nothing in it was altered after it
was written. Integrity asks whether something changed on the way; authenticity asks who wrote it
in the first place.

**Non-repudiation** is being able to prove, to a third party, that somebody did something, so they
cannot later deny it. A signed contract has it. A message anybody with the shared password could
have sent does not. Digital signatures (`cryptography` lesson 6) exist largely to provide it.

**Accountability** is being able to trace every action to the person or system that took it.
It needs two things: that each person has their own account (lesson 8 calls this
identification), and that actions are recorded somewhere the person cannot erase. A shared
`admin` account destroys accountability even if nobody misuses it, because when something goes
wrong nobody can say who did it.

**Privacy** is about the person the data describes, not about the organisation holding it. A
company can keep a customer list perfectly confidential and still violate privacy, by collecting
more than it needs or using it for a purpose the customer never agreed to. Lesson 17 covers what
Brazil's LGPD requires.

### The same three, seen from the attacker's side

Some people find it easier to think about what goes wrong. The **DAD triad** names the three
failures that mirror the CIA properties:

| CIA property | DAD failure | at the shop |
|---|---|---|
| confidentiality | **disclosure** | the customer list is posted on a forum |
| integrity | **alteration** | prices are changed in the database |
| availability | **destruction** (or denial) | ransomware encrypts the server |

Both triads describe the same ground. CIA is how a defender states a goal; DAD is how an incident
report states what happened. When you read an incident write-up, ask which of the three
properties was lost, because that tells you which controls failed or were missing.

One more name you will meet is the **Parkerian hexad**, proposed by Donn Parker in 1998. It
keeps the three and adds possession (control of the data, even unread: a stolen backup tape),
authenticity and utility (the data is there but useless, like an encrypted file with no key). It
is less common in standards, and nothing in this course depends on it.
