---
title: Passwords need a slow hash
version: 1
---

A system that checks passwords should not store them; it stores something computed from each one, and
checks a login by computing it again. The tempting choice is SHA-256, and **it is the wrong one,
because it is fast**. Lesson 10 measured this machine encrypting 12.5 gigabytes a second; a fast hash
is in the same league, which is exactly what anybody holding a stolen copy of the stored values wants.
They hash every common password and every variation of it, and compare.

The defence has three parts:

| part | what it does |
|---|---|
| a **salt**, random per password | the same password stored twice gives two different values, so one computation cannot be compared against every account at once |
| a **slow** function | each guess costs a deliberate amount of time and memory: Argon2id, scrypt, bcrypt, or PBKDF2 with a high iteration count |
| parameters stored beside the value | the cost can be raised later for new passwords without breaking the old ones |

Lesson 10's file encryption used `-pbkdf2 -iter 600000` for exactly this reason: when a key is derived
from something a person typed, every guess should cost 600,000 rounds of hashing rather than one.

For network equipment the lesson is practical. Routers, switches and firewalls store their own
administrator passwords, and older configuration formats use weak or reversible encodings. Some
vendors' configurations still show passwords in a form that can be reversed without effort, which
means a backup of the configuration is a list of passwords. Check which format a device uses, prefer
its strongest one, and treat configuration backups as secrets.
