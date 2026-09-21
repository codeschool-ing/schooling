---
title: Greedy by default, and the character that fixes it
version: 1
---

```
*        zero or more
+        one or more
?        zero or one
{3}      exactly three
{2,4}    two to four
{2,}     two or more
```

Each applies to the thing immediately before it: `ab+` is an `a` and one or more `b`s;
`(ab)+` is one or more `ab`s.

## Greedy

**`*` and `+` take as much as they can**, then give characters back one at a time until the rest
of the pattern fits.

```python
re.search(r"<(.*)>", "<a> and <b>").group(1)      # 'a> and <b'
```

That is not a bug. `.*` matched everything up to the last `>`, because everything up to the last
`>` is more than everything up to the first — and the pattern still fitted.

## Lazy

```python
re.search(r"<(.*?)>", "<a> and <b>").group(1)     # 'a'
```

`*?` and `+?` take as LITTLE as they can, then add one character at a time until the rest fits.
One question mark, and the meaning reverses.

## And the better answer

```python
re.search(r"<([^>]*)>", "<a> and <b>").group(1)   # 'a'
```

"Anything that is not a `>`" says what you meant, cannot run past the closing bracket, and does
not depend on the reader knowing which kind of quantifier this is. **Describing the shape beats
tuning the greed**, and it is faster too.

## `?` after a group

```python
r"colou?r"          # color or colour
r"(\+\d{1,3} )?"    # an optional country code, present or not
```

The optional group is how a pattern handles "this part may not be there" — and when it is
absent, its group is `None` rather than an empty string, which is a check somebody forgets.

## The one that is always wrong

```python
r".*"
```

Alone, it matches everything, including nothing. Inside a pattern it is the greedy trap above.
**If your pattern contains `.*` and you are not sure why, that is the line to look at first.**
