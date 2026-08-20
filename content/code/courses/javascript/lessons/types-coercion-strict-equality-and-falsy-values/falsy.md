---
title: The eight falsy values
---

In an `if`, any value becomes a boolean. **Eight** of them become `false` — and everything else becomes `true`, including `[]`, `{}` and `"0"`:

- `false`, `0`, `-0`, `0n` (BigInt zero)
- `""` (the empty string)
- `null`, `undefined`, `NaN`

The practical trap is that `0` and `""` are falsy: `if (quantity)` ignores a quantity of zero, and `if (name)` ignores an empty name — in both cases treating "exists and is zero/empty" as "does not exist".

```schooling-example
{
  "language": "javascript",
  "file": "falsy.js",
  "parts": [
    {
      "code": "const config = { retries: 0, title: \"\" };",
      "note": "Two legitimate values that happen to be falsy. Zero retries is a decision; an empty title is one too."
    },
    {
      "code": "console.log(config.retries || 3);\nconsole.log(config.title || \"no title\");",
      "note": "The classic `||` runs over both: it tests \"is it falsy?\", not \"is it absent?\". The zero the user chose became three."
    },
    {
      "code": "console.log(config.retries ?? 3);\nconsole.log(JSON.stringify(config.title ?? \"no title\"));",
      "note": "`??` only kicks in for `null` and `undefined` — the zero and the empty string pass through untouched. It is the operator most default-value `||`s really wanted to be. (The `JSON.stringify` is there only so the empty string shows as `\"\"` instead of a blank line.)"
    }
  ],
  "output": "3\nno title\n0\n\"\""
}
```
