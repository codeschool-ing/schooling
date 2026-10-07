---
title: Fields, private fields and arrow fields
version: 1
---

A class body can declare **fields**: properties every instance gets, written once at the top
instead of inside the constructor. A field whose name starts with `#` is **private**, reachable
only from code inside the class body:

```javascript
class Account {
  #balanceCents = 0;
  static #opened = 0;

  constructor(owner) {
    this.owner = owner;
    Account.#opened += 1;
  }

  deposit(cents) {
    if (cents <= 0) throw new RangeError("a deposit must be positive");
    this.#balanceCents += cents;
  }

  get balance() {
    return this.#balanceCents;
  }

  static count() {
    return Account.#opened;
  }

  static isAccount(value) {
    return #balanceCents in value;
  }
}

const acc = new Account("ana");
acc.deposit(1990);
console.log(acc.balance, Account.count());
console.log(acc, Object.keys(acc), JSON.stringify(acc));
acc.balance = 5;
console.log(acc.balance);
console.log(Account.isAccount(acc), Account.isAccount({ owner: "bia" }));
```

```
ana@dev:~/js$ node private.js
1990 1
Account { owner: 'ana' } [ 'owner' ] {"owner":"ana"}
1990
true false
```

- `#balanceCents = 0` gives every account its own balance, and **nothing outside the class can see
  it**. Printing `acc` shows only `owner`; `Object.keys` and `JSON.stringify` do not list it;
- `get balance()` lets the outside read it. `acc.balance = 5` tried to write it and **was ignored**:
  a getter with no setter cannot be assigned. This file is not strict, so it was ignored silently;
  lesson 20 shows the same line throwing in strict mode;
- `static #opened` is private to the class itself, counting accounts;
- **`#balanceCents in value` asks whether an object was made by this class**, a check that cannot be
  fooled by an object that merely looks like an account.

## Privacy enforced before the program runs

```javascript
class Account {
  #balanceCents = 0;
}
const acc = new Account();
console.log(acc.#balanceCents);
```

```
ana@dev:~/js$ node peek.js 2>&1 | head -n 5
/home/ana/js/peek.js:5
console.log(acc.#balanceCents);
               ^

SyntaxError: Private field '#balanceCents' must be declared in an enclosing class
```

**Reading a private field from outside is a `SyntaxError`**, found while the file is read, so the
program does not start at all. That is a stronger guarantee than the closure pattern of lesson 6 or
the `WeakMap` of lesson 5, which hid data by keeping it out of reach. Private fields are what to
write today; you will meet the other two in code written before 2022, when they became standard.

## Arrow fields keep their `this`

A field can hold a function. **An arrow function in a field captures the instance as its `this`**,
because the field's value is created while the constructor runs:

```javascript
"use strict";

class Counter {
  count = 0;
  increment = () => {
    this.count += 1;
    return this.count;
  };
}

const c = new Counter();
const press = c.increment;
press();
press();
console.log(c.count, Object.hasOwn(c, "increment"));
console.log(new Counter().increment === c.increment);
```

```
ana@dev:~/js$ node field-arrow.js
2 true
false
```

`press` is `c.increment` taken away from its dot, the exact mistake of lesson 6, and it worked
twice. This is the shorter form of lesson 7's bind-in-the-constructor, with the same consequence:
**each instance gets its own copy of the function**, not a shared one on the prototype, which the
last line shows. That costs a little memory per object, and it buys a handler you can pass anywhere
and remove later with the same reference.
