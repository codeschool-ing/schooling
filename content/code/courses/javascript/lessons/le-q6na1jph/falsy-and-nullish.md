---
title: Falsy values, and the operator for missing ones
version: 1
---

An `if` does not need a boolean. It converts whatever it is given, and **the conversion is the
same one `Boolean()` performs**. A value that converts to `false` is called **falsy**, and there
are exactly eight of them. Everything else is **truthy**:

```javascript
const values = [false, 0, -0, 0n, "", null, undefined, NaN, "0", "false", " ", [], {}, -1];

for (const v of values) {
  const shown = typeof v === "string" ? JSON.stringify(v) : Array.isArray(v) ? "[]" : typeof v === "object" && v ? "{}" : Object.is(v, -0) ? "-0" : typeof v === "bigint" ? `${v}n` : String(v);
  console.log(shown.padEnd(10), Boolean(v));
}
```

```
ana@dev:~/js$ node falsy.js
false      false
0          false
-0         false
0n         false
""         false
null       false
undefined  false
NaN        false
"0"        true
"false"    true
" "        true
[]         true
{}         true
-1         true
```

## The list to remember

`false`, `0`, `-0`, `0n`, `""`, `null`, `undefined` and `NaN`. **That is all of them.** The six
lines below show the values people expect to be falsy and are not: the strings `"0"` and
`"false"`, a string holding a space, an empty array and an empty object are all truthy. `if (list)`
is true for an empty list, so to ask whether an array has items, ask `list.length > 0`.

## `||` gives back a value

`||` and `&&` are not limited to `true` and `false`. **They return one of their two operands**:

```javascript
console.log("Iracema" && 1865);
console.log("" && 1865);
console.log(null || "no title");
console.log(!!"Iracema", !!"");
```

```
ana@dev:~/js$ node andor.js
1865

no title
true false
```

`a && b` gives `a` if it is falsy and `b` otherwise; `a || b` gives `a` if it is truthy and `b`
otherwise. The empty line in the output is `""`, returned by `&&` because it was falsy. `!!` turns
any value into its boolean, which is what the last line printed.

## `||` for defaults, and where it goes wrong

The habit of writing `value || fallback` for "use the fallback if there is no value" is everywhere
in older code, and **it treats every falsy value as missing**. A setting of zero is a real setting:

```javascript
function shelfSize(settings) {
  const withOr = settings.perShelf || 20;
  const withNullish = settings.perShelf ?? 20;
  console.log(withOr, withNullish);
}

shelfSize({ perShelf: 35 });
shelfSize({ perShelf: 0 });
shelfSize({});
```

```
ana@dev:~/js$ node defaults.js
35 35
20 0
20 20
```

With `perShelf: 0`, **`||` threw the zero away and used 20**. `??`, the nullish coalescing
operator, falls back only for `null` and `undefined`, so it kept the zero. The third call had no
setting at all, and both agreed.

**Use `??` for defaults.** Reach for `||` when an empty string or a zero really should be replaced,
and write a comment saying so, because the next reader will wonder. Lesson 4 adds `?.`, its
companion, for reading a property of something that might not be there.
