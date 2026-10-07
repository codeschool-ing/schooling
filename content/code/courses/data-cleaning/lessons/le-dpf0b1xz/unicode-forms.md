---
title: Unicode forms: one letter, two spellings
version: 1
---

**Unicode lets most accented letters be written two ways**: as one character, `ã`, or as the plain
letter followed by a combining accent, `a` plus the combining tilde, U+0303. Both draw the same on screen. They are different
strings, of different lengths, and they never compare equal.

```
ana@lab:~/clean$ python -c "import unicodedata; a = 'S\u00e3o'; b = unicodedata.normalize('NFD', a); print(a == b, len(a), len(b), [hex(ord(ch)) for ch in b], unicodedata.normalize('NFC', b) == a)"
False 3 4 ['0x53', '0x61', '0x303', '0x6f'] True
```

`'São'` written with the single character is three characters long. Decomposed, it is four: `S`, `a`,
the combining tilde `0x303`, `o`. The two are not equal, and normalising the decomposed one back
gives the original.

The two forms have names. **NFC** is the composed form, one character per accented letter, which is
what keyboards on most systems produce and what this course stores. **NFD** is the decomposed form.
Some systems produce NFD on purpose — older macOS file systems stored file names that way — and
Quitanda Verde's app is one of them: every name and city it sent is in NFD. Lesson 1
found the symptom, 213 São Paulos that looked like the other 458.

The fix is one call, with no judgement in it:

- pandas: `.str.normalize("NFC")`
- Python: `unicodedata.normalize("NFC", text)`
- PostgreSQL: `normalize(text, NFC)`

**Normalise every text column to NFC on the way in**, as routinely as trimming spaces. It changes
nothing a reader can see and makes equal what should be equal. The other two forms, NFKC and NFKD,
also fold "compatibility" characters — a superscript `²` into `2`, the ligature `ﬁ` into `fi` — which
is right for a matching key and wrong for stored text, because it loses information.
