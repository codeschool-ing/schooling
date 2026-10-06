---
title: Data that might not be there
version: 1
---

Data from outside your program has holes in it. A book without an author, a user without an
address, a list of reviews that is empty. **Reading a missing property gives `undefined`, and
reading a property of `undefined` throws**:

```javascript
const fromApi = { title: "Iracema", reviews: [] };
console.log(fromApi.author);
console.log(fromApi.author.name);
```

```
ana@dev:~/js$ node missing.js 2>&1 | head -n 6
undefined
/home/ana/js/missing.js:3
console.log(fromApi.author.name);
                           ^

TypeError: Cannot read properties of undefined (reading 'name')
```

This is the commonest runtime error in JavaScript, and its message is worth learning to read.
**`Cannot read properties of undefined (reading 'name')` means the thing to the left of `.name` was
`undefined`**, here `fromApi.author`. The fix is never on the `name` side; it is finding out why
the left side was missing.

## `?.`

When a missing part is a normal possibility rather than a bug, **optional chaining** says so. `?.`
reads the property if the left side has a value, and **stops and gives `undefined` if the left
side is `null` or `undefined`**, instead of throwing:

```javascript
const fromApi = { title: "Iracema", reviews: [] };

console.log(fromApi.author?.name);
console.log(fromApi.author?.name ?? "unknown author");
console.log(fromApi.reviews?.[0]?.stars);
console.log(fromApi.format?.());

const withAuthor = { title: "Iracema", author: { name: "José de Alencar" } };
console.log(withAuthor.author?.name);
```

```
ana@dev:~/js$ node optional.js
undefined
unknown author
undefined
undefined
José de Alencar
```

- `fromApi.author?.name` stopped at the missing author;
- **`?.` pairs with `??` from lesson 2** to give a fallback in the same expression:
  `"unknown author"`;
- `?.[0]` is the bracket form, for an index or a computed name. `reviews` existed and was empty, so
  `[0]` was `undefined`, and the second `?.` stopped there;
- `?.()` calls a function only if it exists. `fromApi.format` does not, so nothing was called;
- when the data is complete, `?.` is an ordinary `.`, as the last line shows.

## Where not to use it

**`?.` hides the error, so it belongs only where a missing value is expected.** Scattering it over
every dot turns a bug into a blank space on a screen. If a book must have an author, let the
program fail at the place it finds one without, where the message is clear, rather than three
screens later where an empty name is all anybody can see.
