---
title: Test data is not production data
version: 1
---

The fastest way to get realistic test data is to copy production. It is also the way a company
ends up with customers' names, addresses and purchase histories on every developer's laptop, in
every CI log, and in every staging database with weaker access control than the real one. Under the
LGPD, the Brazilian data protection law, a copy of personal data is processing like any other: it
needs a purpose and a legal basis, and "it was convenient for the tests" is neither.

**Test data should be made, not taken.** Everything `shipquote`'s tests use was written for them.
Its e-mail addresses, for instance:

```
ana@laptop:~/shipquote$ grep -rhoE '[a-z]+@[a-z.]+' tests/ | sort | uniq -c
      3 bia@example.org
```

One address, three uses, at `example.org`. That domain, with `example.com` and `example.net`, is
reserved by RFC 2606 for documentation and testing, so a test that accidentally sends mail sends it
nowhere and reaches no real person. The same care applies to the other identifiers a Brazilian
system handles:

| identifier | what tests should use |
|---|---|
| e-mail | an address at `example.org`, `example.com` or `example.net` |
| CEP | real CEPs of public places, such as `01310-100` on Avenida Paulista |
| CPF | numbers generated to pass the check digits, never a real person's |
| card number | the test numbers a payment provider publishes for its sandbox |
| IP address | the documentation ranges, `192.0.2.0/24` and its two siblings |

## When production data is really needed

Sometimes it is: a bug that only one customer's data reproduces, or performance that depends on
real distributions. The defensible answers, in order of preference:

1. **Reproduce the shape, not the data.** Find what is special about the failing record, a name
   with an apostrophe, an address with 300 characters, and write a factory case for it.
2. **Anonymise before copying.** Replace names, documents and contacts with generated values,
   consistently, so relationships survive and people do not. Do it inside production's own
   boundary, before the data leaves.
3. **Bring the test to the data**, under production's access controls, rather than the data to
   the test.

## Data in the pipeline

From lesson 5 on, tests run on machines you do not watch, and their output is kept in logs that
many people can read. A test that prints a customer record on failure publishes it. Lesson 9 is
about keeping secrets out of the pipeline; personal data deserves the same treatment, and the
cheapest way to keep it out of the logs is never to have it in the tests.
