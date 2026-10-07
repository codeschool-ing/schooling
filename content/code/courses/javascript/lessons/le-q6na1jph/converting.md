---
title: Converting on purpose
version: 1
---

Text that looks like a number is still text. A value typed into a form, read from a file or taken
from a web address arrives as a **string**, and before you calculate with it you turn it into a
number. **Do it yourself, explicitly**, so that the conversion happens where you can see it. There
are three tools, and they disagree:

```javascript
const inputs = ["42", "42px", "3.14", "1,5", "", " ", "0x1A", "08", null, undefined, true, []];

console.log("input".padEnd(11), "Number()".padEnd(10), "parseInt()".padEnd(11), "parseFloat()");
for (const v of inputs) {
  const shown = typeof v === "string" ? JSON.stringify(v) : Array.isArray(v) ? "[]" : String(v);
  console.log(
    shown.padEnd(11),
    String(Number(v)).padEnd(10),
    String(parseInt(v, 10)).padEnd(11),
    String(parseFloat(v)),
  );
}
```

```
ana@dev:~/js$ node convert.js
input       Number()   parseInt()  parseFloat()
"42"        42         42          42
"42px"      NaN        42          42
"3.14"      3.14       3           3.14
"1,5"       NaN        1           1
""          0          NaN         NaN
" "         0          NaN         NaN
"0x1A"      26         0           0
"08"        8          8           8
null        0          NaN         NaN
undefined   NaN        NaN         NaN
true        1          NaN         NaN
[]          0          NaN         NaN
```

## Three rules, read off the table

**`Number()` converts the whole value or gives up.** `"42px"` is `NaN` because of the `px`. That is
usually what you want from input a person typed: a field that says `42px` is not a number, and
`NaN` lets you notice.

**`parseInt` and `parseFloat` read from the left and stop at the first character they cannot
use.** `"42px"` gives `42`. That suits text you know starts with a number, such as a CSS value. It
also means `"3.14"` through `parseInt` quietly becomes `3`, and `"1,5"` becomes `1`.

**The empty string is the trap.** `Number("")` and `Number(" ")` are `0`, not `NaN`, so an empty
form field silently turns into zero. Check for empty text before converting, or use `parseFloat`,
which gives `NaN`.

Two smaller lessons from the table: `parseInt` should always get its second argument, the base,
and with base 10 it reads `"0x1A"` as `0`; and `Number(null)` is `0` while `Number(undefined)` is
`NaN`, another place where the two "no value" values behave differently.

## The decimal comma

**JavaScript's decimal separator is the point, whatever the reader's language.** `"1,5"` is not
one and a half to `Number()`. Text typed by a person in Brazil, Portugal or most of Europe may use
a comma, and the conversion has to replace it first:

```javascript
const n = 42;
console.log(String(n), n.toString(), `${n}`);
console.log(n.toString(2), n.toString(16));
console.log((1234.5).toFixed(2), (1234.5).toLocaleString("pt-BR"));
console.log(Number("1,5".replace(",", ".")));
```

```
ana@dev:~/js$ node to-string.js
42 42 42
101010 2a
1234.50 1.234,5
1.5
```

The other direction is `String(n)`, `n.toString()` or a template, and all three agree. `toString`
also takes a base, so `42` in binary is `101010`. For a person, `toLocaleString("pt-BR")` writes
the number the way a Brazilian reader expects, with the comma and the point swapped. **Keep the
locale for what you show, and the point for what you calculate.**
