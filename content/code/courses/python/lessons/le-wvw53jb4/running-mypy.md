---
title: Running it, and reading one error properly
version: 2
---

```sh
pip install mypy
mypy app/report.py        # one file
mypy -p app               # the package, by name
mypy app/                 # the directory
```

```sh
app/report.py:4: error: Argument 1 to "find" has incompatible type "int"; expected "str"  [arg-type]
Found 1 error in 1 file (checked 3 source files)
```

## The four parts of a line

`app/report.py:4` — where to look. `error:` — its severity; `note:` lines are extra information
about the error above them and are not failures of their own. Then the sentence. Then
`[arg-type]` in brackets: **the error code**, which is the part people skip and the part you need.

The code is what you search for, what you put inside a `# type: ignore[...]`, and what you name
in `disable_error_code`. The sentence is for you; the code is for the tooling.

## The summary line counts two different things

```sh
Found 1 error in 1 file (checked 3 source files)
```

Three files were checked because `report.py` imports `rates.py`, which pulls in `__init__.py`
with it. **Errors are reported in the files you asked about; imports are read to understand
them.**

## The mistake everybody makes once

```sh
mypy app/rates.py
```

```sh
Success: no issues found in 1 source file
```

The same project, the same bug, a clean bill of health — because the bug is in `report.py`, which
CALLS `rates.find` wrongly. `rates.py` itself is fine.

**The error is almost never in the file you changed.** It is in the file that calls it. Run the
checker over the package, never over the file you happen to have open.

## `reveal_type`, when you want to know what it thinks

```python
data = json.load(f)
reveal_type(data)
```

```sh
note: Revealed type is "Any"
```

It needs no import and it is not a function — the checker recognises the name and answers. At run
time the bare name raises `NameError`; `from typing import reveal_type` gives you a real one
(3.11 and up) that prints `Runtime type is 'int'`. Use it when an error makes no sense: it is
usually because something upstream is `Any`.

## The cache

The first run over a package takes a second or two; the second takes a fraction of it, because
`.mypy_cache/` holds what was worked out about each module. Put it in `.gitignore` next to
`__pycache__` and never commit it.
