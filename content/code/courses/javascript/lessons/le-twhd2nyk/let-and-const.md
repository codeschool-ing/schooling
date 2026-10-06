---
title: let and const
version: 1
---

A name in JavaScript is declared before it is used, and **the keyword you declare it with says
whether it may be pointed at something else later.** `const` says no. `let` says yes.

```javascript
const title = "Dom Casmurro";
title = "Iracema";
```

```
ana@dev:~/js$ node const.js 2>&1 | head -n 5
/home/ana/js/const.js:2
title = "Iracema";
      ^

TypeError: Assignment to constant variable.
```

The error is the point: a name declared with `const` cannot be **reassigned**, and the engine
refuses at the line that tries.

## `const` fixes the name, not the value

The commonest misreading of `const` is that it makes a value unchangeable. It does not:

```javascript
const shelf = ["Dom Casmurro"];
shelf.push("Iracema");
console.log(shelf);

let read = 0;
read = read + 1;
console.log(read);
```

```
ana@dev:~/js$ node const-array.js
[ 'Dom Casmurro', 'Iracema' ]
1
```

`shelf` still names the same array; **the array itself grew**. `const` promised only that `shelf`
would never be made to name a different array. Changing what is inside an object or an array is
called mutation, and lesson 4 is about when that is what you want and when it is a bug. `read`,
declared with `let`, was given a new number, which is exactly what `let` is for.

## A name lives in its block

Both `let` and `const` belong to the **block** they are declared in: the pair of braces around
them.

```javascript
const year = 1899;
if (year < 1900) {
  let century = "nineteenth";
  console.log(century);
}
console.log(century);
```

```
ana@dev:~/js$ node block.js 2>&1 | head -n 6
nineteenth
/home/ana/js/block.js:6
console.log(century);
            ^

ReferenceError: century is not defined
```

Inside the `if`, `century` exists and prints. Outside, it was never declared, so the engine stops
with a `ReferenceError`. **A name that cannot leak out of its block cannot collide with a name
somewhere else**, which is most of the reason these two keywords replaced the older `var`.
Lesson 3 is about `var` and why it behaves differently.

## Which one to use

**`const` by default, `let` when you will reassign.** Most names in a program are given a value
once, and saying so with `const` tells the next reader that they can stop looking for changes. When
a counter goes up or a total accumulates, `let` says that too. You will see `var` in old code and
in old tutorials; in new code there is no case where it is the better choice.
