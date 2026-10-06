---
title: Hoisting: names exist before their line
version: 1
---

The usual picture of a program is that a line runs, then the next. It is right for what lines
**do**, and wrong for what they **declare**. Before a block or a function starts running, the engine
reads it through and **creates every name declared anywhere inside it**. That step is called
hoisting, as if the declarations were lifted to the top, though nothing in your file moves.

What each name holds in the meantime depends on how it was declared.

## `var`: created as `undefined`

```javascript
console.log(title);
var title = "Iracema";
console.log(title);
```

```
ana@dev:~/js$ node hoist-var.js
undefined
Iracema
```

The first line reads `title` before line 2 has run, and gets `undefined`. **A `var` is created and
given `undefined` straight away**; the `= "Iracema"` part stays on its own line and runs when the
program gets there. Reading a variable too early does not fail, it quietly gives the wrong value,
which is the worst of the options.

## Function declarations: created whole

```javascript
console.log(greet("ana"));

function greet(name) {
  return `hello, ${name}`;
}

console.log(typeof later);
later();

var later = function () {
  return "too late";
};
```

```
ana@dev:~/js$ node hoist-function.js 2>&1 | head -n 7
hello, ana
undefined
/home/ana/js/hoist-function.js:8
later();
^

TypeError: later is not a function
```

`greet` is called on line 1 and written on line 3, and it worked. **A function declaration is
hoisted with its body**, so it can be called anywhere in its scope. That is what lets a file put
its main logic at the top and the helpers underneath, which reads well.

`later` is a different case. It is a `var` whose value happens to be a function, so it was hoisted
the way `var` is: as `undefined`. `typeof later` printed `undefined`, and calling it gave
**`TypeError: later is not a function`**, a message that makes sense once you know the name existed
and held nothing callable.

## `let`, `const` and `class`: created, but untouchable

They are hoisted as well. **The engine creates the name at the start of the block and refuses
every use of it until the declaration's own line has run.** The next section is about that stretch
of the block, which has a name of its own.

| declared with | exists from | holds before its line |
|---|---|---|
| `var` | the start of the function | `undefined` |
| `function` declaration | the start of the scope | the whole function |
| `let`, `const`, `class` | the start of the block | nothing: reading it throws |
