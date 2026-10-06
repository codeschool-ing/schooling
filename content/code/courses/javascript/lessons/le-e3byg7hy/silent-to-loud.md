---
title: Silent failures that become errors
version: 1
---

Several kinds of assignment cannot happen: the property is read-only, the object is frozen,
the value is a primitive. **Sloppy mode ignores them without a word; strict mode throws a `TypeError`.**
Four of them, first in a sloppy file:

```javascript
const frozen = Object.freeze({ title: "Iracema" });
frozen.title = "Ubirajara";
console.log(frozen.title);

class Account {
  #cents = 1990;
  get balance() { return this.#cents; }
}
const acc = new Account();
acc.balance = 5;
console.log(acc.balance);

"Iracema".year = 1865;
console.log(delete Object.prototype);
```

```
ana@dev:~/js$ node silent.js
Iracema
1990
false
```

The title stayed `Iracema`, the balance stayed `1990`, the string got no `year`, and `delete` simply
answered `false`. **Every line ran, nothing was changed, and nothing said so.** The getter-only balance
is the one lesson 8 left for this lesson: `acc.balance = 5` was ignored there for exactly this reason.

The same four, in an ES module, which is strict:

```javascript
const attempts = {
  "assign to a frozen object": () => { Object.freeze({ title: "Iracema" }).title = "Ubirajara"; },
  "assign to a getter-only property": () => {
    class Account { get balance() { return 1990; } }
    new Account().balance = 5;
  },
  "set a property on a string": () => { "Iracema".year = 1865; },
  "delete Object.prototype": () => { delete Object.prototype; },
};
for (const [what, attempt] of Object.entries(attempts)) {
  try {
    attempt();
    console.log(`${what}: silently ignored`);
  } catch (err) {
    console.log(`${what}: ${err.name}: ${err.message}`);
  }
}
```

```
ana@dev:~/js$ node loud.mjs
assign to a frozen object: TypeError: Cannot assign to read only property 'title' of object '#<Object>'
assign to a getter-only property: TypeError: Cannot set property balance of #<Account> which has only a getter
set a property on a string: TypeError: Cannot create property 'year' on string 'Iracema'
delete Object.prototype: TypeError: Cannot delete property 'prototype' of function Object() { [native code] }
```

Each one threw, and **each message says precisely what could not be done**: the frozen property is
read-only, the property has only a getter, a string cannot take a property, `prototype` cannot be
deleted. Those are bugs either way. The difference is whether you find them at the line that made
them or, later, from a value that is not what you set.

## `Object.freeze`

The first line is worth knowing on its own. **`Object.freeze(obj)` makes an object's properties
read-only and stops new ones being added.** It is shallow, like the spread of lesson 4: a frozen object
holding an array still holds a changeable array. It is useful for constants and configuration that
nothing should change, and in strict code an attempt to change one fails loudly.
