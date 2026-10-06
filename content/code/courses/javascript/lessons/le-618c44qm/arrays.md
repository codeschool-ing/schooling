---
title: Arrays: ordered lists
version: 1
---

**An array is an object whose properties are numbered from 0**, with a `length` and a set of
methods for lists. Square brackets make one and read from one:

```javascript
const shelf = ["Iracema", "Dom Casmurro", "O Cortiço"];
console.log(shelf[0], shelf.length, shelf[shelf.length - 1], shelf.at(-1));
console.log(shelf[10]);

shelf.push("Macunaíma");
const removed = shelf.shift();
console.log(removed, shelf);

console.log(shelf.includes("O Cortiço"), shelf.indexOf("Iracema"));
console.log(shelf.slice(0, 2), shelf.length);
shelf.splice(1, 1);
console.log(shelf);
```

```
ana@dev:~/js$ node arrays.js
Iracema 3 O Cortiço O Cortiço
undefined
Iracema [ 'Dom Casmurro', 'O Cortiço', 'Macunaíma' ]
true -1
[ 'Dom Casmurro', 'O Cortiço' ] 3
[ 'Dom Casmurro', 'Macunaíma' ]
```

## Reading

`shelf[0]` is the first item and `shelf.length - 1` the index of the last; `shelf.at(-1)` says the
same thing in fewer characters, counting from the end. An index past the end reads as `undefined`,
like a missing property, **and does not throw**.

## Changing

`push` adds at the end and `pop` removes from the end; `unshift` and `shift` do the same at the
start. `shift` returned `"Iracema"` and the array moved up. **`splice(start, count)` removes items
in place**, and here took out the one at index 1. `slice(start, end)` is the near twin that does
not change anything: it returns a new array, and `shelf.length` was still 3 afterwards.

The pair `splice` and `slice` is the commonest confusion with arrays, and the rule underneath it is
the one to keep: **some methods change the array they are called on, and some return a new one.**
`push`, `pop`, `shift`, `unshift`, `splice`, `sort` and `reverse` change it. Everything else in
this lesson returns something new.

## Sorting

```javascript
const years = [1899, 1865, 1928, 1890];
const sizes = [10, 9, 1, 100];

console.log(sizes.sort());
console.log(sizes.sort((a, b) => a - b));

const sorted = years.toSorted((a, b) => a - b);
console.log(sorted, years);

const authors = ["Érico", "Clarice", "Jorge", "Ana"];
console.log(authors.toSorted());
console.log(authors.toSorted((a, b) => a.localeCompare(b, "pt-BR")));
```

```
ana@dev:~/js$ node sort.js
[ 1, 10, 100, 9 ]
[ 1, 9, 10, 100 ]
[ 1865, 1890, 1899, 1928 ] [ 1899, 1865, 1928, 1890 ]
[ 'Ana', 'Clarice', 'Jorge', 'Érico' ]
[ 'Ana', 'Clarice', 'Érico', 'Jorge' ]
```

Three surprises in one program:

- **`sort()` with no argument compares items as strings**, so `100` sorts before `9`, for the
  reason lesson 2 gave: `"1"` comes before `"9"`. Pass a comparison function, `(a, b) => a - b`,
  which returns a negative number when `a` should come first;
- `sort` changed `sizes` itself. **`toSorted` returns a sorted copy and leaves the original**, as
  `years` shows. It arrived in 2023, alongside `toReversed` and `toSpliced`;
- the default order of strings is by character code, which puts `Érico` after `Jorge`. **For text a
  person will read, compare with `localeCompare`**, which knows that `É` sorts with `E` in
  Portuguese.
