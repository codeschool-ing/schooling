---
title: `bytes` against `str`, and when you need neither
version: 2
---

```python
with open(path, "rb") as f:
    data = f.read()        # bytes, not str
```

`"rb"` and `"wb"` skip the decoding entirely. You get a `bytes` object: a sequence of numbers
from 0 to 255, printed as `b"..."`.

## The two conversions

```python
text = data.decode("utf-8")      # bytes → str
data = text.encode("utf-8")      # str   → bytes
```

**Decode on the way in, encode on the way out**, and keep `str` everywhere in between. A program
that carries `bytes` through its middle is one that will compare a `b"name"` with a `"name"` and
get `False`.

## When you need binary

An image, a PDF, a zip, anything compressed, and anything where you are copying rather than
reading. For copying, `shutil.copyfile` is the version you should write instead.

Also a file whose encoding you do not know yet: read the first few hundred bytes as binary and
look at them before deciding.

## When you do not

Almost always. CSV, JSON, logs, source code and configuration are text, and `open(path,
encoding="utf-8")` is the whole answer. If you find yourself decoding by hand inside a loop, the
mode was wrong two lines earlier.

## The one that catches people

```python
>>> b"91" + 1
TypeError: can't concat int to bytes
>>> b"a" == "a"
False
```

`bytes` and `str` never compare equal and never concatenate. This arrives most often from a
library that returns bytes — `subprocess`, a socket, a hash — and the fix is a `.decode()` at
that boundary rather than a cast further in.

`hashlib` is the ordinary case: it wants bytes, so `h.update(text.encode("utf-8"))`, and it gives
you back a `hexdigest()` that is a `str` again.
