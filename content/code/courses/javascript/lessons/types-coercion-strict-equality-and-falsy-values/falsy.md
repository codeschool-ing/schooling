---
title: The eight falsy values
---

In an `if`, any value becomes a boolean. **Eight** of them become `false` — and everything else becomes `true`, including `[]`, `{}` and `"0"`:

- `false`, `0`, `-0`, `0n` (BigInt zero)
- `""` (the empty string)
- `null`, `undefined`, `NaN`

The practical trap is that `0` and `""` are falsy: `if (quantity)` ignores a quantity of zero, and `if (name)` ignores an empty name — in both cases treating "exists and is zero/empty" as "does not exist".

[object Object]
