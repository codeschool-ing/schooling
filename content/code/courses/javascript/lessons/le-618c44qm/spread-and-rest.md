---
title: Three dots: spread and rest
version: 1
---

`...` means two opposite things depending on where it stands. **Where values are expected, it
spreads**: it takes an array or an object apart and puts its pieces in place. **Where names are
declared, it gathers the rest** into one array or object.

```javascript
const fiction = ["Iracema", "Dom Casmurro"];
const poetry = ["Lira dos Vinte Anos"];
const all = [...fiction, ...poetry, "Macunaíma"];
console.log(all);

const years = [1899, 1865, 1928];
console.log(Math.max(...years));

const defaults = { theme: "light", perPage: 20, language: "en" };
const chosen = { perPage: 50, language: "pt" };
console.log({ ...defaults, ...chosen });
console.log({ ...chosen, ...defaults });

function total(label, ...amounts) {
  return `${label}: ${amounts.reduce((a, b) => a + b, 0)}`;
}
console.log(total("pages", 112, 256, 208));
```

```
ana@dev:~/js$ node spread.js
[ 'Iracema', 'Dom Casmurro', 'Lira dos Vinte Anos', 'Macunaíma' ]
1928
{ theme: 'light', perPage: 50, language: 'pt' }
{ perPage: 20, language: 'en', theme: 'light' }
pages: 576
```

## Spread

- **`[...fiction, ...poetry, "Macunaíma"]`** builds a new array from the items of two others plus
  one more. `[...shelf]` on its own is the usual way to copy an array, and it is shallow in the same
  way an object spread is;
- `Math.max` takes separate numbers, not an array, so **`Math.max(...years)` spreads the array
  into arguments**. Before spread existed this was written with `apply`, which lesson 7 covers;
- with objects, spread copies the properties into a new object, and **when two have the same name,
  the one that comes later wins**. `{ ...defaults, ...chosen }` is the standard way to apply a
  user's choices over defaults. Swapping the order threw the choices away, as the fourth line
  shows.

## Rest

In a parameter list, `...amounts` gathers every argument after the named ones into a real array.
`total` took a label and **any number of amounts**, and summed them with `reduce`. A rest parameter
has to be the last one, since it takes everything that is left.

Rest also works in destructuring, which the next section is about: `const [first, ...others] =
list` keeps the first item and gathers the rest.

**Spread makes a copy, and only one level deep.** That is enough to keep a change to the copy's
top level out of the original, and not enough for anything nested, as the shallow-copy figure in
this lesson showed.
