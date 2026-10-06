---
title: Names at the top of a script
version: 1
---

The last difference shows at the top level of a file, outside every function. **In a browser, a
`var` or a function declared at the top of a classic script becomes a property of the global
object**, `window`, which every script on the page shares. A `let` or a `const` does not:

```html
<!doctype html>
<script>
  var shelfCount = 12;
  let readerName = "ana";
  function openShelf() {}

  console.log(window.shelfCount, window.readerName, typeof window.openShelf);
</script>
<script>
  console.log(shelfCount, readerName);
</script>
```

```
ana@dev:~/js$ page globals.html
12 undefined function
12 ana
```

`window.shelfCount` is 12 and `window.openShelf` is the function, while `window.readerName` is
`undefined`. Yet the second line shows that the second `<script>` could still read `readerName`.
**Top-level `let` and `const` are shared between the page's scripts too**, in a scope of their own
beside `window` rather than on it.

The difference matters because `window` already holds hundreds of properties. **A top-level `var`
called `name`, `status` or `top` collides with one the browser put there**:

```html
<!doctype html>
<script>
  var name = 42;
  var top = "the top shelf";
  console.log(typeof name, name);
  console.log(top === window);
</script>
```

```
ana@dev:~/js$ page collide.html
string 42
true
```

`window.name` keeps only strings, so the number 42 came back as the text `"42"`. `window.top` cannot
be replaced at all, so the assignment did nothing and `top` is still the window. Neither raised an
error. With `let` there is no collision to have.

## Node is different

```javascript
var shelfCount = 12;
console.log(globalThis.shelfCount);
```

```
ana@dev:~/js$ node globals.js
undefined
```

**Each Node file has a scope of its own**, so its top-level `var` stays in the file and
`globalThis`, the name for the global object in every host, does not get it. Lesson 9 explains
where that scope comes from. A browser `<script type="module">` behaves the same way, and that is
one of the reasons modules replaced classic scripts.

## The global you never declared

```javascript
function countBooks() {
  total = 7;
}

countBooks();
console.log(total, globalThis.total);
```

```
ana@dev:~/js$ node implicit.js
7 7
```

`total` was never declared anywhere. **Assigning to an undeclared name creates a property on the
global object**, so the function quietly created a global that every other file in the program can
now see and overwrite. A typo in a variable name does the same thing. That is not a feature
anybody wants, and lesson 20 shows the mode, strict mode, in which this line is a
`ReferenceError`.
