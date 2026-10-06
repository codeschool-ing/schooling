---
title: Statements, and the semicolons you can leave out
version: 1
---

A program is a list of **statements**, run one after another. A statement does something:
declares a name, calls a function, decides between two paths. Inside many statements sit
**expressions**, the pieces that produce a value: `2 + 3`, `"Dom" + " Casmurro"`, `year < 1900`.
`node -p` printed the value of one expression; a file runs statements.

Comments are for the reader and the engine skips them. `//` runs to the end of the line, and
`/* … */` can cover several.

## The semicolon

A statement ends with `;`. **JavaScript also lets you leave it out**, and fills it in for you
where a line break makes the statement complete. The rule is called automatic semicolon insertion,
and it is why half the code you will read has semicolons and the other half has none. Both are
fine. What is not fine is not knowing the two places where the rule does something you did not
mean.

## Where a line break ends a statement you wanted to continue

```javascript
function book() {
  return
  {
    title: "Dom Casmurro"
  };
}

console.log(book());
```

```
ana@dev:~/js$ node asi-return.js
undefined
```

**A line break straight after `return` ends the statement there.** The function returns nothing,
which is `undefined`, and the object below it is never reached. The fix is to start the object on
the same line as `return`: `return {`.

## Where a line break does not end a statement you wanted to end

```javascript
const shelf = "fiction"
const label = shelf
(function () {
  console.log("sorting the shelf")
})()
```

```
ana@dev:~/js$ node asi-join.js 2>&1 | head -n 5
/home/ana/js/asi-join.js:2
const label = shelf
              ^

TypeError: shelf is not a function
```

ana meant three statements. JavaScript saw two, because a line that starts with `(` can continue
the line above it: `shelf(function () { … })` is a call. **So the string `"fiction"` was called
as a function**, and the error points at line 2, which looks innocent. The same happens with a
line that starts with `[` or a backtick.

## Which style to pick

**Write the semicolons, and let a formatter do it.** A team picks one style and a tool such as
Prettier applies it on every save, so nobody argues about it in review. If you join a codebase
without semicolons, the one habit to keep is the second case: a line that starts with `(`, `[` or
a backtick gets a `;` in front of it.
