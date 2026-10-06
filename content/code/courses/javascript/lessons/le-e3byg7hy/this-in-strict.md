---
title: this in a plain call
version: 1
---

Lesson 6 said a plain call gives `undefined` for `this` in strict mode and promised the other half.
Here it is:

```javascript
function sloppyThis() {
  return this === globalThis;
}
function strictThis() {
  "use strict";
  return this;
}
console.log(sloppyThis(), strictThis());
```

```
ana@dev:~/js$ node this-check.js
true undefined
```

**In sloppy mode, a function called on its own gets the global object as `this`**; in strict mode it
gets `undefined`. That one difference decides how a lost method fails:

- in strict code, `this.prefix` on `undefined` throws at once: `Cannot read properties of undefined`,
  the message lesson 6 taught you to read as "this method lost its object";
- in sloppy code, `this.prefix` reads a property of the global object, which is almost always
  `undefined`, and the method carries on and produces `undefined: Iracema`, as lesson 6's
  `withFunction` did. **Worse, an assignment like `this.count = 0` creates a global**, so a lost method
  can quietly change state that every other script shares.

Strict mode turns a lost `this` from a wrong result into an error at the call. Classes are strict, so
a class method that loses its object always fails the loud way, and that is one reason classes made
this bug easier to find.
