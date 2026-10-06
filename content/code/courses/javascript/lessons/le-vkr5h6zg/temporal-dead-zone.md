---
title: The temporal dead zone
version: 1
---

**The temporal dead zone is the part of a block between its opening brace and a `let` or `const`
declaration**, where the name already exists and every use of it throws. "Temporal" because it is
about when the line runs, not where it sits:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of one block. When the block starts, the let name title is created but not initialised; from there to its declaration line is the temporal dead zone, where reading it throws a ReferenceError. From the declaration line on, it holds its value.\"><defs><marker id=\"tdz-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M40 140 L700 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#tdz-ah-wire)\"></path><rect x=\"40\" y=\"70\" width=\"330\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"205.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">temporal dead zone</text><text x=\"205.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reading title throws ReferenceError</text><rect x=\"390\" y=\"70\" width=\"270\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">initialised</text><text x=\"525.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">title === &quot;Iracema&quot;</text><text x=\"40\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">{ the block starts</text><text x=\"390\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">let title = &quot;Iracema&quot;;</text><text x=\"40\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the name is created here</text><text x=\"390\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the declaration runs</text></svg>", "caption": "The name exists from the start of the block, and cannot be used until its declaration has run."}
```

## Two different errors

```
ana@dev:~/js$ node tdz-read.js 2>&1 | grep Error
ReferenceError: Cannot access 'title' before initialization
ana@dev:~/js$ node not-declared.js 2>&1 | grep Error
ReferenceError: title is not defined
```

Read the two messages side by side, because they say different things. **`Cannot access 'title'
before initialization` means the name exists in this scope and its line has not run yet.**
`title is not defined` means there is no such name anywhere the engine looked. The first is an
ordering problem; the second is usually a typo or a missing import.

## `typeof` is not safe here

`typeof` answers `"undefined"` for a name that was never declared, and people use it as a safe
probe. **Inside the dead zone it throws like any other read**:

```javascript
console.log(typeof missing);
console.log(typeof title);
let title = "Iracema";
```

```
ana@dev:~/js$ node tdz.js 2>&1 | head -n 6
undefined
/home/ana/js/tdz.js:2
console.log(typeof title);
        ^

ReferenceError: Cannot access 'title' before initialization
```

## The trap: a name shadowed from the top of its block

```javascript
const year = 1899;

function check() {
  console.log(year);
  const year = 1865;
}

check();
```

```
ana@dev:~/js$ node shadow.js 2>&1 | head -n 5
/home/ana/js/shadow.js:4
  console.log(year);
              ^

ReferenceError: Cannot access 'year' before initialization
```

There is a `year` outside the function, and `console.log(year)` looks as if it should read it.
**The `const year` on line 5 is hoisted to the top of `check`'s body**, so from the opening brace
the inner name covers the outer one, a situation called **shadowing**, and line 4 is inside the
inner one's dead zone. With `var` the same program would print `undefined` and carry on.

## Why it is a good thing

`var` gave you `undefined` and let a wrong value travel. **The dead zone turns the same mistake into
an error at the line that made it**, with a message that names the variable. The cure is the one
lesson 1 already gave: declare names at the top of their block, before the code that uses them.
