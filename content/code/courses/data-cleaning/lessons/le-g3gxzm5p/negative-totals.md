---
title: Negative totals: an impossible value with a known cause
version: 1
---

**Lesson 2 found 137 orders with a negative total**, every one with a coupon worth more than the
basket and the delivery fee together. They are not outliers in the statistical sense — a few reais
below zero sits close to the minimum of the distribution — but they are impossible: nobody is paid to
buy groceries.

The cause is known, so the decision can be made by rule rather than case by case. The website
subtracted the coupon in full; the payment gateway, asked by Ana, confirms that it never charges a
negative amount, so what these customers paid was zero. **The total is set to zero and flagged**, and
the flag says why: `coupon above basket: charged 0`.

Two things make this the right call rather than a convenient one:

- **the replacement comes from the business, not from the data.** Zero is what was charged, as the
  payments team states; it is not an estimate of anything;
- **the rule behind it is reported upstream.** A checkout that lets a coupon exceed the basket will
  keep producing these rows, and the fix belongs in the website, where a coupon can be capped at the
  basket's value.

The general pattern: **a value that breaks a rule of the domain is invalid, and invalid values with
a known cause get a rule, a flag and a note to whoever owns the cause.** Lesson 1 called this
validity; here it is the same dimension met in a number column.
