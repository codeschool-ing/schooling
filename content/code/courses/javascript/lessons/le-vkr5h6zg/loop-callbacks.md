---
title: The loop whose callbacks all see 3
version: 1
---

This is the bug `var` is famous for, and it still appears in code reviews. A loop schedules some
work for later, and **every piece of work sees the value the counter had at the end**:

```javascript
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log("var", i), 0);
}
```

```javascript
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log("let", i), 0);
}
```

```
ana@dev:~/js$ node loop-var.js
var 3
var 3
var 3
ana@dev:~/js$ node loop-let.js
let 0
let 1
let 2
```

`setTimeout(fn, 0)` runs `fn` after the current program has finished, which here means after the
loop is over. Lesson 15 is about what "zero" really means; for now, what matters is that **the
callbacks run after the loop has finished counting**.

## Why `var` prints 3 three times

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two loops scheduling three callbacks each. With var there is one variable i for the whole loop, all three callbacks point at it, and by the time they run it holds 3. With let each turn of the loop has its own i, holding 0, 1 and 2, and each callback points at its own.\"><defs><marker id=\"loops-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"loops-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"336\" height=\"242\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"184\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">for (var i …)</text><rect x=\"36\" y=\"62\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M156 79 L232 145\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-amber)\"></path><rect x=\"36\" y=\"116\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M156 133 L232 145\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-amber)\"></path><rect x=\"36\" y=\"170\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M156 187 L232 145\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-amber)\"></path><rect x=\"236\" y=\"122\" width=\"96\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"284.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">i = 3</text><text x=\"284\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one variable</text><rect x=\"368\" y=\"14\" width=\"336\" height=\"242\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">for (let i …)</text><rect x=\"388\" y=\"62\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M508 79 L580 79\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-phosphor)\"></path><rect x=\"584\" y=\"62\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">i = 0</text><rect x=\"388\" y=\"116\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M508 133 L580 133\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-phosphor)\"></path><rect x=\"584\" y=\"116\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">i = 1</text><rect x=\"388\" y=\"170\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M508 187 L580 187\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-phosphor)\"></path><rect x=\"584\" y=\"170\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">i = 2</text><text x=\"536\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one variable per turn</text></svg>", "caption": "A callback keeps the variable, not the value it had when the callback was made."}
```

With `var`, there is **one `i` for the whole loop**, because `var` belongs to the function, or here
the file, and not to the loop's block. Each arrow function remembers the variable `i`, not the
number it held when the arrow was written. By the time the three run, the loop has pushed `i` to 3,
the value that made `i < 3` false, and all three read that.

With `let`, **each turn of the loop gets its own `i`**, a fresh binding initialised with the value
the previous turn ended on. Each arrow remembers a different variable, and each variable still
holds the number it had on its turn.

This is the language's rule rather than a trick of `setTimeout`. **A function keeps the variables
it can see, not copies of their values**, and lesson 6 gives that a name, a closure, and makes it
the centre of the lesson. The same bug appears whenever a loop creates functions for later: event
handlers attached in a loop (lesson 12), requests whose results arrive later (lesson 14).

## The fix, then and now

The fix today is one word: `let`. Code written before 2015 used other fixes, which you will
recognise if you meet them. The usual one wraps the body in a function that is called at once with
`i`, which creates a new variable per turn by hand:

```javascript
for (var i = 0; i < 3; i++) {
  (function (j) {
    setTimeout(() => console.log("old fix", j), 0);
  })(i);
}
```

```
ana@dev:~/js$ node loop-iife.js
old fix 0
old fix 1
old fix 2
```

**If you meet that shape in a codebase, it is this bug's old fix**, and replacing `var` with `let`
lets you delete it.
