---
title: The field type changes the keyboard
---

On a computer, `type="email"` and `type="text"` look the same. On a phone they do not: the type picks which keyboard appears.

- `email` — brings the `@` and the dot onto the first screen.
- `tel` — the big numeric keypad, the dialling one.
- `number` — numeric, but careful: it refuses leading zeros and formatting characters, so it does **not** work for postcodes, national IDs or card numbers.
- `url`, `date`, `search` — each with its own keyboard and its own native picker.

For a postcode or a masked phone number, the pair that works is `type="text"` with `inputmode="numeric"`: a numeric keypad, without the restrictions of `number`.
