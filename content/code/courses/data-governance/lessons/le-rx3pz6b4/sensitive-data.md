---
title: Sensitive personal data
version: 1
---

Some personal data can hurt the person far more if it leaks, is misused or is used to decide about
them. The LGPD lists it in **article 5, II**: personal data about

- racial or ethnic origin;
- religious conviction;
- political opinion;
- membership of a trade union or of a religious, philosophical or political organisation;
- **health** or sex life;
- genetic or biometric data,

*when linked to a natural person.* That list is closed — the law does not let a company decide that
something else is "sensitive" for legal purposes — and everything on it is treated more strictly:
fewer legal bases (lesson 7), more care, heavier consequences when it goes wrong.

## At Ipê

A pharmacy lives inside the fourth item. `health.prescriptions` is health data by any reading: who
was prescribed what, by which doctor, when. That table was put in its own schema in the lab from the
start, and lessons 1 and 2 kept every role out of it. But a list of sensitive *tables* is the easy
part.

**Data about health is health data whatever table it sits in.** The next section finds it in a
table called `sales.order_items`, which nobody would think to protect like a medical record, and
section 9 finds it typed into support tickets. The law's test is what the data *reveals*, not
where it is filed.

## Biometrics and genetics

Ipê does not collect either, and most data teams never will — until a supplier offers "log in with
your face" or a partner sends a wellness dataset. Both are on the list, both are hard to change if
they leak (a password can be reset; a fingerprint cannot), and both deserve a conversation with the
DPO before the first row is stored.
