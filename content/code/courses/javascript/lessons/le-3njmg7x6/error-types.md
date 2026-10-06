---
title: The kinds of error
version: 1
---

The language throws a handful of `Error` subclasses, and **the name says which kind of mistake it
was**, which is often enough to know where to look:

```javascript
const attempts = [
  () => null.title,
  () => undefinedName,
  () => new Array(-1),
  () => JSON.parse("{oops"),
  () => decodeURIComponent("%"),
];
for (const attempt of attempts) {
  try {
    attempt();
  } catch (err) {
    console.log(err.constructor.name.padEnd(14), err instanceof Error, "|", err.message);
  }
}
```

```
ana@dev:~/js$ node types.js
TypeError      true | Cannot read properties of null (reading 'title')
ReferenceError true | undefinedName is not defined
RangeError     true | Invalid array length
SyntaxError    true | Expected property name or '}' in JSON at position 1 (line 1 column 2)
URIError       true | URI malformed
```

| name | means | you met it in |
|---|---|---|
| **`TypeError`** | a value of the wrong kind: calling a non-function, reading a property of `null` | lessons 1, 4, 6 |
| **`ReferenceError`** | a name that does not exist, or is in its dead zone | lessons 1, 3 |
| **`RangeError`** | a number outside what is allowed, or a stack that ran out | lessons 7, 13 |
| **`SyntaxError`** | code or JSON that cannot be parsed | lessons 1, 9, 16 |
| `URIError` | a malformed escape in a URL | here |

All of them are `instanceof Error`, which is what code checks when it wants to be sure it caught a
real error.

## Your own errors

**Extending `Error` gives your program's failures names of their own**, so callers can tell them
apart:

```javascript
class LoanError extends Error {
  constructor(message, options) {
    super(message, options);
    this.name = "LoanError";
  }
}

class OverdueError extends LoanError {
  constructor(reader, days) {
    super(`${reader} has a book ${days} days overdue`);
    this.name = "OverdueError";
    this.reader = reader;
    this.days = days;
  }
}

function lend(reader) {
  if (reader === "bia") throw new OverdueError("bia", 12);
  try {
    JSON.parse("{not json");
  } catch (err) {
    throw new LoanError(`could not read ${reader}'s card`, { cause: err });
  }
}

for (const reader of ["bia", "ana"]) {
  try {
    lend(reader);
  } catch (err) {
    console.log(err.name, err instanceof LoanError, err instanceof OverdueError, "|", err.message);
    if (err.cause) console.log("  caused by:", err.cause.name, "|", err.cause.message);
    if (err instanceof OverdueError) console.log("  days:", err.days);
  }
}
```

```
ana@dev:~/js$ node custom.js
OverdueError true true | bia has a book 12 days overdue
  days: 12
LoanError true false | could not read ana's card
  caused by: SyntaxError | Expected property name or '}' in JSON at position 1 (line 1 column 2)
```

- `LoanError` is the family and `OverdueError` one member, so **`instanceof` answers at either
  level**: the overdue error was both;
- setting `this.name` is what makes the name appear in messages and stack traces; without it,
  every custom error would call itself `Error`;
- `OverdueError` carries **data**, `reader` and `days`, so a caller can act on them rather than parse
  the message, which is written for people and may change;
- the second reader failed for a different reason underneath, a card that was not valid JSON. **The
  `cause` option keeps the original error attached**, so the message can speak in terms of loans
  while the cause says exactly what broke.
