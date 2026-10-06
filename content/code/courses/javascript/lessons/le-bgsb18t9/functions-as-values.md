---
title: Functions are values
version: 1
---

In JavaScript **a function is a value**, of the same standing as a number or a string. It can be
given a name, passed to another function, returned from one, and kept in an array or an object.
Languages where that is true are said to have **first-class functions**, and everything else in
this lesson follows from it:

```javascript
function shout(text) {
  return text.toUpperCase() + "!";
}

const say = shout;
console.log(say("hello"));

function applyTwice(fn, value) {
  return fn(fn(value));
}
console.log(applyTwice(shout, "hi"));

function makeGreeting(greeting) {
  return (name) => `${greeting}, ${name}`;
}
const hello = makeGreeting("Hello");
const ola = makeGreeting("Olá");
console.log(hello("ana"), "/", ola("ana"));

console.log(typeof shout, shout.name, shout.length);
```

```
ana@dev:~/js$ node values.js
HELLO!
HI!!
Hello, ana / Olá, ana
function shout 1
```

## Four things you can do with a function value

- **give it another name.** `const say = shout` copied the reference, as lesson 4 showed for
  objects, so `say` and `shout` are one function;
- **pass it as an argument.** `applyTwice` received `shout` and called it twice. A function passed
  in to be called later is a **callback**, and you have already written dozens: every function
  given to `map` or `filter` in lesson 4 was one;
- **return it.** `makeGreeting` builds a new arrow function each time it is called and hands it
  back. A function that takes or returns functions is a **higher-order function**;
- **ask about it.** `typeof` says `"function"`, `name` is the name it was declared with, and
  `length` is the number of parameters it declares.

## Why this matters

`hello` and `ola` came from the same `makeGreeting`, and each remembered a different greeting. **The
`greeting` parameter belonged to a call of `makeGreeting` that had already returned**, yet the arrow
function could still read it. That is not a trick of arrow functions; it is how every function in
the language works, and it has a name. The next two sections build up to it: first how a function
finds a name, then what happens when the function outlives the place it was made.
