---
title: Case: for comparing, and for showing
version: 1
---

**Capitals carry no meaning in a city name, so for comparison they should not count.** `SAO PAULO`,
`São Paulo` and `são paulo` are one city; any key built for grouping or matching should fold them
together. The cascade at the end of this lesson shows that lower-casing is the largest single step:
it takes the cities from 21 spellings to 12.

Three functions do it, and they are not the same:

```
ana@lab:~/clean$ python -c "print('Straße'.lower(), 'Straße'.casefold(), 'DA SILVA'.title(), 'mcdonald'.title())"
straße strasse Da Silva Mcdonald
```

- `lower()` turns capitals into small letters. It is enough for Portuguese and English.
- `casefold()` is the stricter version meant for comparison: German `ß` becomes `ss`, so `Straße`
  and `STRASSE` compare equal. When a key will be compared, `casefold()` is the correct choice; on
  this data the two give the same result.
- `title()` capitalises each word, and is wrong for names: `DA SILVA` becomes `Da Silva` where
  Portuguese writes `da Silva`, and `mcdonald` becomes `Mcdonald`. **No mechanical rule writes a
  person's name correctly.**

## Two columns, not one

That last point is why case is the first place this lesson's main rule shows up: **clean a copy for
comparing, and keep the original for showing.** A key column — lower case, no accents, single
spaces — is what groups, joins and matches. The column people read keeps the name as the person or
the canonical list wrote it. Lowering the name itself would put `ana lima` on the next invoice, and
title-casing it would put `Ana Lima Da Silva`.

For a value with a fixed canonical form, such as a city, the display column is not the original
either: it comes from a list, as the section on abbreviations does. For a person's name, the
original is the only correct form there is, and the key exists so that nobody has to change it.
