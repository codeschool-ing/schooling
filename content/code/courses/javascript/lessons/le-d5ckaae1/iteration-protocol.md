---
title: What for of asks for
version: 1
---

`for…of`, spread and destructuring all work on more than arrays, and they all work the same way
underneath. **They ask the value for an iterator, and then ask the iterator for one item at a time.**
The rules for that conversation are called the **iteration protocol**, and they are small enough to
run by hand:

```javascript
const shelf = ["Iracema", "Dom Casmurro"];
const it = shelf[Symbol.iterator]();

console.log(it.next());
console.log(it.next());
console.log(it.next());
console.log(it.next());
console.log(typeof Symbol.iterator, typeof shelf[Symbol.iterator]);
```

```
ana@dev:~/js$ node protocol.js
{ value: 'Iracema', done: false }
{ value: 'Dom Casmurro', done: false }
{ value: undefined, done: true }
{ value: undefined, done: true }
symbol function
```

## The two halves

- **An iterable** is an object with a method stored under the key `Symbol.iterator`. Calling that
  method returns an iterator. Arrays have one, which is why `shelf[Symbol.iterator]` is a function;
- **an iterator** is an object with a `next()` method. Each call returns `{ value, done }`: the next
  item and `done: false`, or, when there is nothing left, `done: true`. Once done, it stays done, as
  the fourth call shows.

`Symbol.iterator` is a **symbol**, the primitive type lesson 2 listed and never used. A symbol is a
key that cannot collide with any string, so the language could add this method to every built-in
object without breaking code that already had a property called `"iterator"`.

## What a string iterates over

```javascript
const word = "Olá \u{1F44B}";
console.log(word.length, [...word].length);
console.log([...word].map((ch) => ch.codePointAt(0).toString(16)));
console.log(word.split("").map((unit) => unit.charCodeAt(0).toString(16)));
```

```
ana@dev:~/js$ node strings.js
6 5
[ '4f', '6c', 'e1', '20', '1f44b' ]
[ '4f', '6c', 'e1', '20', 'd83d', 'dc4b' ]
```

`word` holds five characters and has a `length` of 6. **`length` counts UTF-16 code units, and the
emoji at the end takes two of them**, `d83d` and `dc4b`, as `split("")` shows. A string's iterator
walks by **code point** instead, so `[...word]` has five items and the emoji is one of them. If you
need to count or reverse what a reader sees as characters, spread the string first; `split("")`
cuts some of them in half.
