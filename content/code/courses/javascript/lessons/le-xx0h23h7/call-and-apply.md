---
title: call and apply: choosing this for one call
version: 1
---

Lesson 6 showed that `this` is decided by how a function is called. **`call` and `apply` are the
way to say it explicitly**: they run the function once, now, with the `this` you pass as their
first argument.

```javascript
"use strict";

function describe(open, close) {
  return `${open}${this.title}, ${this.year}${close}`;
}

const iracema = { title: "Iracema", year: 1865 };
const casmurro = { title: "Dom Casmurro", year: 1899 };

console.log(describe.call(iracema, "[", "]"));
console.log(describe.call(casmurro, "(", ")"));
console.log(describe.apply(casmurro, ["<", ">"]));
console.log(describe("{", "}"));
```

```
ana@dev:~/js$ node call.js 2>&1 | head -n 9
[Iracema, 1865]
(Dom Casmurro, 1899)
<Dom Casmurro, 1899>
/home/ana/js/call.js:4
  return `${open}${this.title}, ${this.year}${close}`;
                        ^

TypeError: Cannot read properties of undefined (reading 'title')
    at describe (/home/ana/js/call.js:4:25)
```

`describe` is not a method of either book. **`describe.call(iracema, "[", "]")` ran it with `this`
set to `iracema`**, and the remaining arguments went to the function's own parameters. Called the
same way with `casmurro`, the same function described the other book. The last line called it
plainly, with no `this` at all, and it threw the error lesson 6 taught you to recognise.

## The only difference

`apply` does exactly what `call` does, and **takes the function's arguments as one array** instead
of one by one. `describe.apply(casmurro, ["<", ">"])` is `describe.call(casmurro, "<", ">")`. A
mnemonic people use: **a**pply takes an **a**rray, **c**all takes **c**ommas.

## When you will write them

Less often than you will read them. A function written to use `this` on whatever object it is
given is an older style; today the object would usually be a parameter, `describe(book, "[", "]")`,
which needs no `call` at all. Where `call` is still the right tool is **borrowing**: running a
function that belongs to one kind of object on another kind, which is the borrowing section of this
lesson. And `apply` survives in code that predates spread, which the next section is about.
