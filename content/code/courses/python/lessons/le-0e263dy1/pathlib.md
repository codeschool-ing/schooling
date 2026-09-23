---
title: A path is an object, not a string
version: 2
---

```python
from pathlib import Path

data = Path("data")
rows = data / "2026" / "rows.csv"       # data/2026/rows.csv
rows.exists()
rows.read_text(encoding="utf-8")
```

The `/` operator joins. It uses the right separator for the machine it is on, which is the first
reason this exists: `"data" + "/" + name` is a bug on Windows and an odd-looking line everywhere.

## The parts

```python
rows.name          # 'rows.csv'
rows.stem          # 'rows'
rows.suffix        # '.csv'
rows.parent        # Path('data/2026')
rows.parts         # ('data', '2026', 'rows.csv')
```

Every one of those is a function somebody has written by hand with `split(".")` and got wrong for
a file called `archive.tar.gz` or one with no extension at all.

## Reading and writing

```python
text = path.read_text(encoding="utf-8")
path.write_text(text, encoding="utf-8")
```

For a whole small file, that is the entire operation — no `open`, no closing, nothing to forget.
Lesson 9 is the `with open(...)` form, which is what you want for a large file read line by line.

**Always pass `encoding="utf-8"`.** Without it Python uses the machine's default, which differs
between machines — and a file that reads perfectly here fails on the server with a
`UnicodeDecodeError` naming a byte.

## Finding files

```python
for p in Path("data").glob("*.csv"):
for p in Path("data").rglob("*.csv"):       # every level below
```

`glob` is one level, `rglob` is all of them. Both give `Path` objects, so the next line can ask
`p.stem` without parsing anything.

## Making and testing

```python
path.exists()  path.is_file()  path.is_dir()
path.parent.mkdir(parents=True, exist_ok=True)
```

`exist_ok=True` is the difference between an idempotent script and one that fails on its second
run. `parents=True` makes the intermediate directories.

## The one thing to remember

**A path is not a string, and the moment you `+` one you have left `pathlib` behind.** If a
library insists on a string, `str(path)` at that boundary — and nowhere else.
