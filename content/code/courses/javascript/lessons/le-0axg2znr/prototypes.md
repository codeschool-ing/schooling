---
title: Every object has a prototype
version: 1
---

**An object can have a link to another object, called its prototype.** When you read a property
the object does not have, JavaScript does not give up: it looks on the prototype, and returns
what it finds there. `Object.create` makes a new object with the prototype you choose, which
makes it the clearest way to see this:

```javascript
const reader = {
  greet() {
    return `hello from ${this.name}`;
  },
};

const ana = Object.create(reader);
ana.name = "ana";

console.log(ana.greet());
console.log(Object.getPrototypeOf(ana) === reader);
console.log(Object.hasOwn(ana, "greet"), "greet" in ana);
console.log(ana);

ana.greet = () => "my own greeting";
console.log(ana.greet());
delete ana.greet;
console.log(ana.greet());
```

```
ana@dev:~/js$ node proto.js
hello from ana
true
false true
{ name: 'ana' }
my own greeting
hello from ana
```

- `ana` was created empty, with `reader` as its prototype, and then given a `name`. **`ana.greet()`
  worked although `ana` has no `greet`**: the lookup found it on `reader`;
- inside `greet`, `this` was `ana`, not `reader`. The method was found on the prototype, **but it
  was called on `ana`**, and lesson 6's rule, the object before the dot, still decides `this`;
- `Object.hasOwn` says `greet` is not `ana`'s own property, while `in` says it can be reached.
  Printing `ana` shows only its own properties, `{ name: 'ana' }`;
- giving `ana` its own `greet` **shadowed** the one on the prototype; deleting it uncovered the
  inherited one again.

## Reading is inherited, writing is not

```javascript
const reader = { shelves: [] };
const ana = Object.create(reader);
const bia = Object.create(reader);

ana.shelves.push("Romance");
console.log(bia.shelves);

bia.shelves = ["Poetry"];
console.log(ana.shelves, bia.shelves);
```

```
ana@dev:~/js$ node shared.js
[ 'Romance' ]
[ 'Romance' ] [ 'Poetry' ]
```

`ana.shelves.push("Romance")` **read** `shelves`, found the array on the prototype, and changed
that array. `bia` reads the same one, so she saw "Romance" too. `bia.shelves = ["Poetry"]` is a
**write**, and a write always goes on the object itself, so it gave `bia` her own property and left
the prototype's alone.

That is the rule to take away. **Lookups travel up the chain; assignments stay on the object.** It
is also why a prototype should hold methods, which are shared on purpose, and not data that each
object needs its own copy of. Every class in this lesson follows that split.
