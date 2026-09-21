---
title: `__name__ == "__main__"`, and the script that ran twice
version: 1
---

```python
def main():
    ...

if __name__ == "__main__":
    main()
```

Every module has a `__name__`. When Python RUNS a file it sets that file's `__name__` to
`"__main__"`; when it IMPORTS one it sets it to the module's name. So the block runs when the
file is the program and not when it is a library.

## What it is actually for

Not ceremony, and not style. It is what lets one file be both **a tool you run** and **a module
you import**, which is what makes it testable: lesson 15's tests import your file, and without
this guard the import would run the program.

```python
$ python report.py          # __name__ is "__main__" — main() runs
>>> import report           # __name__ is "report"   — it does not
```

## The script that ran twice

Without the guard, a file that does its work at the top level does that work every time anybody
imports it. The failure looks like this: a script writes a file, a test imports the script to
check one function, and the test suite writes the file too — **on somebody else's machine, in a
directory nobody expected.**

## Put the work in a function

```python
if __name__ == "__main__":
    total = 0
    for row in load():          # works, and nothing here can be tested
        ...
```

The body of the guard should be one call. Everything inside it is unreachable from a test and
unreachable from another program, so it is the one place in your file where code cannot be
reused — keep it two lines long.

## `python -m`

```sh
python -m json.tool data.json
python -m http.server
```

`-m` runs a MODULE as a program, finding it the way an import does. Several standard-library
modules have a useful one, and a package of your own gets one by putting the guarded block in
`__main__.py`.
