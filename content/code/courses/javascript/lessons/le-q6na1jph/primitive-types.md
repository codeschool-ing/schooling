---
title: Seven primitives, and objects
version: 1
---

**Every value in JavaScript is either a primitive or an object.** A primitive is a single,
unchangeable value: a number, a piece of text, true or false. An object is a collection of values
you can change, and arrays and functions are objects too. There are seven primitive types, and
`typeof` names the type of any value:

```javascript
const values = [42, 3.14, "Dom Casmurro", true, undefined, null, 10n, Symbol("id"), {}, [], () => {}];

for (const v of values) {
  console.log(typeof v);
}
console.log(Array.isArray([]), Array.isArray({}));
```

```
ana@dev:~/js$ node types.js
number
number
string
boolean
undefined
object
bigint
symbol
object
object
function
true false
```

Read the list against the output:

| value | `typeof` | the type |
|---|---|---|
| `42`, `3.14` | `number` | every number, whole or not, is one type |
| `"Dom Casmurro"` | `string` | text |
| `true` | `boolean` | `true` or `false` |
| `undefined` | `undefined` | a name with no value yet |
| `null` | `object` | **a deliberate "nothing"; the answer is a mistake** |
| `10n` | `bigint` | a whole number of any size |
| `Symbol("id")` | `symbol` | a value guaranteed to be unique |
| `{}`, `[]` | `object` | objects |
| `() => {}` | `function` | a function, which is an object that can be called |

## Two answers to remember

**`typeof null` is `"object"`, and that is a bug from 1995 that can never be fixed**: too many
pages on the web check for it. `null` is a primitive. To test for it, compare directly:
`value === null`.

**`typeof []` is `"object"` too**, because an array is an object. `Array.isArray` is the test that
tells them apart, and the last line printed `true false`.

## `undefined` and `null`

Both mean "no value", and the difference is who said so. **`undefined` is what the language gives
you**: a declared name with nothing assigned, a missing property, a parameter nobody passed, the
result of a function with no `return`. **`null` is what a programmer writes** to say "deliberately
empty", such as a book with no cover image yet. Lesson 4 meets both on missing properties, and the
last section of this lesson shows the one operator that treats them alike.

## Primitives cannot change

`"Dom Casmurro".toUpperCase()` returns a new string and leaves the original alone. **No operation
changes a primitive in place**; it always produces another one. That is why `const` on a number or
a string really does fix the value, while `const` on an array, in lesson 1, only fixed the name.
