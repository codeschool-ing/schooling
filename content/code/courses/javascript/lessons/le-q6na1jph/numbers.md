---
title: Numbers, and why 0.1 + 0.2 is not 0.3
version: 1
---

JavaScript has one type for every ordinary number, and **it is a 64-bit binary floating-point
number**, the same format most languages call a double. That choice explains almost every surprise
in this section.

```
ana@dev:~/js$ node -p '0.1 + 0.2'
0.30000000000000004
ana@dev:~/js$ node -p '0.1 + 0.2 === 0.3'
false
ana@dev:~/js$ node -p '(0.1 + 0.2).toFixed(2)'
0.30
```

**Binary cannot hold one tenth exactly**, in the same way decimal cannot hold one third: 0.1 is
stored as the nearest value the format has, which is a hair off. Two of those added together land
on a number that is not the nearest one to 0.3, and `===` compares the stored values exactly. The
third command shows the usual fix for display: `toFixed(2)` rounds to two places, and returns a
**string**, because it is producing text for a person to read.

## Money is counted in cents

Rounding for display is fine. Rounding while you calculate is how a total ends up a cent away from
the receipt. **Keep money as a whole number of the smallest unit**, and divide only to print:

```javascript
const priceCents = 1990;    // R$ 19,90
const quantity = 3;
const totalCents = priceCents * quantity;

console.log(totalCents);
console.log((totalCents / 100).toFixed(2));
console.log(0.1 * 3, 1 * 3 / 10);
```

```
ana@dev:~/js$ node cents.js
5970
59.70
0.30000000000000004 0.3
```

Whole numbers are exact in this format up to a very large limit, so `1990 * 3` is exactly `5970`.
The last line shows that the order of operations matters with fractions: `0.1 * 3` is off, and
`1 * 3 / 10` is not, because it multiplies whole numbers first and divides once.

## The values at the edges

```javascript
console.log(1 / 0, -1 / 0, 0 / 0);
console.log(typeof NaN);
console.log(Number.MAX_SAFE_INTEGER);
console.log(2 ** 53, 2 ** 53 + 1);
console.log(2n ** 53n + 1n);
console.log(7 % 3, -7 % 3);
console.log(Number.isInteger(5.0), Number.isInteger(5.5));
```

```
ana@dev:~/js$ node special.js
Infinity -Infinity NaN
number
9007199254740991
9007199254740992 9007199254740992
9007199254740993n
1 -1
true false
```

Line by line:

- dividing by zero gives `Infinity` or `-Infinity`, and **zero divided by zero is `NaN`**, "not a
  number", which is itself of type `number`. `NaN` is what a calculation produces when it has no
  answer, and this lesson's equality section shows how to test for it;
- `Number.MAX_SAFE_INTEGER` is the largest whole number the format holds exactly. **Past it,
  `2 ** 53 + 1` comes back as `2 ** 53`**: the `+ 1` was lost. Ids from a database that uses
  64-bit integers can be that large, which is why APIs often send them as strings;
- a **BigInt**, written with an `n`, has no such limit, and got `9007199254740993n` right. BigInts
  and ordinary numbers do not mix in one calculation; you convert one to the other on purpose;
- `%` is the remainder, and **it keeps the sign of the left side**: `-7 % 3` is `-1`, not `2`;
- `Number.isInteger` asks whether a number has no fractional part. `5.0` is the same number as `5`.
