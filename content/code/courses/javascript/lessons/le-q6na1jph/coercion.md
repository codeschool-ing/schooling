---
title: Coercion: when the language converts for you
version: 1
---

When an operator gets two values of types it was not built for, JavaScript **converts one of them
without asking**. That is coercion. It is not random; it follows a short list of rules, and these
nine lines touch the ones you will meet:

```javascript
console.log("5" + 3);
console.log("5" - 3);
console.log("5" * "2");
console.log(true + 1);
console.log(null + 1, undefined + 1);
console.log([] + []);
console.log([1, 2] + [3]);
console.log({} + "!");
console.log("3" > "12", 3 > "12");
```

```
ana@dev:~/js$ node coerce.js
53
2
10
2
1 NaN

1,23
[object Object]!
true false
```

## `+` prefers text

**If either side of `+` is a string, `+` joins.** `"5" + 3` turned the 3 into `"3"` and produced
`"53"`. Every other arithmetic operator only means arithmetic, so `-` and `*` convert both sides
to numbers: `"5" - 3` is `2`, and `"5" * "2"` is `10`. `true` becomes `1`, `null` becomes `0` and
`undefined` becomes `NaN`, exactly as `Number()` did in the last section.

## Objects become strings first

An array or an object meeting `+` is first turned into a string. **An array becomes its items
joined with commas**, so `[] + []` is two empty strings, which printed as an empty line, and
`[1, 2] + [3]` is `"1,2" + "3"`. A plain object becomes `"[object Object]"`, which is the text you
will see on a page the first time you print an object where a string was expected.

## Comparing two strings compares text

`"3" > "12"` is `true`, because **two strings are compared character by character, as in a
dictionary**, and `"3"` comes after `"1"`. When one side is a number, the other is converted, and
`3 > "12"` compares 3 with 12. Sorting is where this bites, and lesson 4 shows it.

## Where it happens without you seeing it

A form field always hands you a string, even when it holds digits:

```html
<!doctype html>
<label>Copies <input id="copies" value="10"></label>
<script>
  const copies = document.querySelector("#copies").value;
  console.log(typeof copies);
  console.log(copies + 5);
  console.log(Number(copies) + 5);
</script>
```

```
ana@dev:~/js$ page form.html
string
105
15
```

**`copies + 5` is `"105"`**, and nothing reported an error: a page would happily show a hundred and
five copies. `Number(copies) + 5` is the fix, and the habit it teaches is the one this lesson is
about: **convert at the edge**, where text enters your program, and from there on every value is
already the type the code expects.
