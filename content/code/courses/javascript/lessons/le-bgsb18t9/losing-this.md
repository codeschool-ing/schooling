---
title: How a method loses its object
version: 1
---

The rule "the object before the dot" has a consequence that catches everybody: **take the method
away from its dot, and it has no object any more.**

```javascript
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

console.log(shelf.label("Iracema"));

const label = shelf.label;
console.log(label("Iracema"));
```

```
ana@dev:~/js$ node losing-this.js 2>&1 | head -n 7
Shelf A: Iracema
/home/ana/js/losing-this.js:6
    return `${this.prefix}: ${title}`;
                   ^

TypeError: Cannot read properties of undefined (reading 'prefix')
    at label (/home/ana/js/losing-this.js:6:20)
```

`const label = shelf.label` copied a reference to the function, and `label("Iracema")` called it
on its own, with no dot. By the second rule, `this` was `undefined`, and reading `this.prefix`
threw. **`Cannot read properties of undefined (reading 'prefix')` inside a method almost always
means this**: the method was called without its object.

## Where it happens without an assignment

Nobody writes `const label = shelf.label` on purpose. The same thing happens every time a method
is **passed as a callback**:

```javascript
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

const titles = ["Iracema", "Dom Casmurro"];

console.log(titles.map((t) => shelf.label(t)));
console.log(titles.map(shelf.label));
```

```
ana@dev:~/js$ node callbacks-this.js 2>&1 | head -n 7
[ 'Shelf A: Iracema', 'Shelf A: Dom Casmurro' ]
/home/ana/js/callbacks-this.js:6
    return `${this.prefix}: ${title}`;
                   ^

TypeError: Cannot read properties of undefined (reading 'prefix')
    at label (/home/ana/js/callbacks-this.js:6:20)
```

`titles.map(shelf.label)` hands `map` the function, and `map` calls it with no object in front. The
first line, which wraps the call in an arrow, works, because inside the arrow the call is written
`shelf.label(t)`, with its dot. Passing a method to `setTimeout`, to `addEventListener` (lesson 12)
or to `then` (lesson 14) loses `this` in exactly the same way.

Three fixes, all common:

- **wrap it in an arrow at the point you pass it**, as above. The simplest and the most readable;
- **bind it**, which makes a copy of the function with `this` fixed. That is lesson 7;
- **define the method as an arrow-function class field**, so it never had its own `this`. That is
  lesson 8.

## The callback inside a method

The reverse problem: a method that passes a callback of its own, and wants `this` inside it.

```javascript
const shelf = {
  name: "Classics",
  titles: ["Iracema", "Dom Casmurro"],
  withFunction() {
    return this.titles.map(function (t) {
      return `${this?.name}: ${t}`;
    });
  },
  withArrow() {
    return this.titles.map((t) => `${this.name}: ${t}`);
  },
};

console.log(shelf.withFunction());
console.log(shelf.withArrow());
```

```
ana@dev:~/js$ node arrow-inside.js
[ 'undefined: Iracema', 'undefined: Dom Casmurro' ]
[ 'Classics: Iracema', 'Classics: Dom Casmurro' ]
```

In `withFunction`, the inner `function (t)` is called by `map` on its own, so it gets its own
`this`. This file is not strict, so that `this` is the global object, which has no `name`, and
every line says `undefined`. **In `withArrow`, the arrow has no `this` of its own and uses the
method's**, which is `shelf`. This is the job arrow functions were added to the language for.
