---
title: Make it canonical, then check it
version: 1
---

An allowlist checks characters, and **the same thing can be written in more than one sequence of
characters**. Unicode has a digit one, `1`, and a full-width digit one, `１`, which East Asian
keyboards produce and which looks almost the same on a screen. It has a superscript two, `²`. A
check that does not know about them can say yes to a value the rest of the program reads
differently.

Python's own definitions of "digit" are the instance worth seeing, because the obvious pattern is
the one that is wrong. Save this as `~/sc/booking/digits.py`, in the folder this lesson's
application will use:

```python
# digits.py
import re
import unicodedata

phone = "".join(chr(0xFF10 + int(d)) for d in "11987654321")  # full-width
print(re.fullmatch(r"\d{11}", phone) is not None)
print(re.fullmatch(r"[0-9]{11}", phone) is not None)
print(phone.isdigit(), int(phone))
print("²".isdigit())
print(unicodedata.normalize("NFKC", phone))
```

```
(.venv) ana@vm:~/sc/booking$ python3 digits.py
True
False
True 11987654321
True
11987654321
```

Line by line, that is five facts about Python 3:

1. **`\d` matches any Unicode decimal digit**, full-width ones included, so `\d{11}` accepts the
   full-width phone.
2. **`[0-9]` matches the ten ASCII digits and nothing else**, so it refuses it.
3. `str.isdigit()` agrees with `\d`, and **`int()` reads full-width digits as the numbers they
   look like**. A program can validate one string and store a different-looking one that means the
   same number.
4. `isdigit()` also says yes to `²`, which `int()` refuses; one check, three behaviours.
5. **NFKC normalisation** rewrites compatibility characters into their plain equivalents, and the
   full-width phone becomes `11987654321`.

### Decide, then check the decided form

There are two honest answers to a full-width phone, and either is fine as long as it is chosen on
purpose:

- **refuse it**: the format is ASCII digits, the pattern is `[0-9]{10,11}`, and the error tells the
  patient what to type. That is what Vereda's form does, because a phone number has no reason to
  arrive any other way from a web form.
- **normalise it, then validate the normalised value**: `unicodedata.normalize("NFKC", value)`
  first, and the allowlist on the result. This suits names and free text that people type on
  every kind of keyboard.

What is never fine is the third arrangement: **validating one form and keeping another**. Check
`value`, store `value.strip().lower()`, and the stored value is one nobody checked. The rule is
short: canonicalise first, check the canonical form, and keep exactly what was checked.

### The same rule, for paths

The idea is older than Unicode. A file name that arrives as input can name the same file in many
ways: `exams/lucia.pdf`, `exams/./lucia.pdf`, `exams/../exams/lucia.pdf`. Checking the text for
`..` is a denylist again. The canonical form of a path is the one the operating system resolves,
and **the check that holds is on the resolved path**: resolve it, then confirm it is still inside
the directory it is supposed to be in. Lesson 14 does exactly that for uploaded exams, with
`Path.resolve()` and `is_relative_to()`.
