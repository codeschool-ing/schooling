---
title: The prototype chain
version: 1
---

A prototype is an object, so it has a prototype too, and the lookup keeps going. **The sequence of
prototypes from an object up to the end is its prototype chain**, and every object you have used in
this course has one:

```javascript
const list = ["Iracema"];

let p = list;
const names = [];
while (p !== null) {
  p = Object.getPrototypeOf(p);
  names.push(p === Array.prototype ? "Array.prototype" : p === Object.prototype ? "Object.prototype" : String(p));
}
console.log(names.join("  ->  "));

console.log(Object.hasOwn(Array.prototype, "map"), Object.hasOwn(Object.prototype, "hasOwnProperty"));
console.log(list.map === Array.prototype.map);
console.log(list.missing);
```

```
ana@dev:~/js$ node chain.js
Array.prototype  ->  Object.prototype  ->  null
true true
true
undefined
```

An array's chain is short. Its prototype is `Array.prototype`, which holds `map`, `filter`, `push`
and the rest; that object's prototype is `Object.prototype`, which holds what every object can do,
such as `hasOwnProperty` and `toString`; and **`Object.prototype`'s prototype is `null`, where
every chain ends**. `list.map` is not a copy of `Array.prototype.map`; it is the same function,
found by walking up one step, and `===` says so.

When the walk reaches `null` without finding the name, the answer is `undefined`, as `list.missing`
shows. **A missing property costs a walk of the whole chain**, which is why it is never an error and
never instant.

That explains two things from earlier lessons. The empty object of lesson 5 that already had a
`constructor` had inherited it from `Object.prototype`. And the `Object.create(null)` dictionary of
lesson 7 had **no chain at all**, which is why it had no `hasOwnProperty` to call.

## The name of the link

The link itself is written `[[Prototype]]` in the specification, with double brackets because it
is not a property you can read by name. `Object.getPrototypeOf(obj)` reads it and
`Object.setPrototypeOf` changes it, though changing the prototype of an object that already exists
is slow in every engine and rarely needed. You will also see **`__proto__`** in old code and in
console output: an older accessor for the same link, kept for compatibility, and not the one to
write.

Do not confuse it with **`prototype`**, the ordinary property that functions have. The next
section is about that one, and the difference between the two is the source of most confusion
about this topic.
