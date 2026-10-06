---
title: Spread replaced most of apply
version: 1
---

Before 2015, **the commonest use of `apply` had nothing to do with `this`**. It was the only way to
call a function with the items of an array as separate arguments. Lesson 4's spread does the same
thing, and reads better:

```javascript
const years = [1899, 1865, 1928];
console.log(Math.max.apply(null, years));
console.log(Math.max(...years));

const many = Array.from({ length: 1_000_000 }, (_, i) => i);
console.log(many.reduce((a, b) => Math.max(a, b)));
console.log(Math.max(...many));
```

```
ana@dev:~/js$ node spread-instead.js 2>&1 | head -n 8
1928
1928
999999
/home/ana/js/spread-instead.js:7
console.log(Math.max(...many));
                 ^

RangeError: Maximum call stack size exceeded
```

The first two lines are the same call. `Math.max` ignores `this`, which is why the old version
passed `null` for it. **If you meet `fn.apply(null, list)`, read it as `fn(...list)`**, and you can
usually rewrite it that way.

## The limit both share

The last line threw `RangeError: Maximum call stack size exceeded`. **Every argument of a call
takes room on the call stack**, and a million arguments is more than V8 allows. Spread and `apply`
both turn an array into arguments, so both fail the same way. Where the limit sits depends on the
engine and on how much of the stack is already in use, which is exactly why you do not want to
depend on it.

**For an array of unknown size, do not spread it into a call.** `reduce` walks the array with one
call per item and no growing argument list, and gave `999999` without trouble. Lesson 13 explains
what the call stack is and why it has a size.
