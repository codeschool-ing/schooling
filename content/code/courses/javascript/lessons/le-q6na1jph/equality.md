---
title: Two equals signs or three
version: 1
---

JavaScript has two equality operators. **`===` is strict**: two values are equal only if they are
the same type and the same value. **`==` is loose**: if the types differ, it converts one or both
first, using rules close to the ones in the coercion section, and then compares.

```javascript
console.log(0 == "", 0 == "0", "" == "0");
console.log(0 === "", 0 === "0", "" === "0");
console.log(null == undefined, null === undefined);
console.log(null == 0, null >= 0);
console.log(1 == true, 2 == true);
console.log([1] == 1, [1] === 1);
```

```
ana@dev:~/js$ node equality.js
true true false
false false false
true false
false true
true false
true false
```

## What `==` gets wrong

The first line is the argument against it. `0 == ""` is true, `0 == "0"` is true, and **`"" == "0"`
is false**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three values joined by loose equality. The empty string equals 0, and 0 equals the string zero, but the empty string does not equal the string zero.\"><path d=\"M360 58 L190 182\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><path d=\"M360 58 L530 182\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><path d=\"M210 200 L510 200\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"5 3\"></path><rect x=\"310\" y=\"22\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0</text><rect x=\"90\" y=\"182\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">&quot;&quot;</text><rect x=\"510\" y=\"182\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">&quot;0&quot;</text><text x=\"205\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">&quot;&quot; == 0</text><text x=\"205\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">true</text><text x=\"515\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0 == &quot;0&quot;</text><text x=\"515\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">true</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">&quot;&quot; == &quot;0&quot;</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">false</text></svg>", "caption": "Loose equality is not transitive: two true comparisons do not make the third one true."}
```

A relation where A equals B and B equals C, but A does not equal C, is one nobody can reason with.
The rest of the output adds more. `null == 0` is false while `null >= 0` is true, because `>=`
converts `null` to a number and `==` has a special rule for it. And `1 == true` is true while
`2 == true` is false, because `true` becomes `1`.

**Write `===` and `!==`, always.** With three signs the second line came out all `false`, and the
types decide before anything else does.

**The one exception people make on purpose is `value == null`**, which is true for `null` and for
`undefined` and for nothing else, as the third line shows. It is a short way of saying "no value",
and many style guides allow exactly that one use. `value === null || value === undefined` says the
same in longer words.

## `NaN` is not equal to itself

```javascript
const parsed = Number("forty");
console.log(parsed);
console.log(parsed === NaN, parsed == NaN);
console.log(Number.isNaN(parsed), Object.is(parsed, NaN));
console.log(0 === -0, Object.is(0, -0));
```

```
ana@dev:~/js$ node nan.js
NaN
false false
true true
true false
```

**`NaN` is the one value that is not equal to anything, itself included**, so `parsed === NaN` can
never be true. `Number.isNaN` is the test to use. `Object.is` is a third comparison that treats
`NaN` as equal to `NaN` and, the last line shows, tells `0` from `-0`, which `===` does not; you
will rarely need it.

## Objects are compared by identity

```javascript
const a = { title: "Iracema" };
const b = { title: "Iracema" };
const c = a;
console.log(a === b, a == b, a === c);
console.log(a.title === b.title);
```

```
ana@dev:~/js$ node objects-equal.js
false false true
true
```

`a` and `b` look the same and are two different objects, so **`===` answers `false`: it asks
whether both sides are the same object**, not whether they hold the same things. `c` is another
name for `a`, and that is `true`. To compare contents, compare the properties you care about.
Lesson 4 is about what it means for two names to share one object.
