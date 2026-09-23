---
title: `__name__ == "__main__"`, and the script that ran twice
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Running a file sets its __name__ to __main__, so the guarded block runs. Importing the same file sets __name__ to the module name, so the guarded block does not. One file is both a tool and a library because of that one string.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">report.py</text> <rect x=\"196\" y=\"26\" width=\"328\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">if __name__ == &quot;__main__&quot;: main()</text> <path d=\"M300 64 L182 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"90\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">python report.py</text> <text x=\"182\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">__name__ is &quot;__main__&quot;</text> <rect x=\"20\" y=\"166\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"182\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the guarded block runs</text> <path d=\"M420 64 L558 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"396\" y=\"90\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">import report</text> <text x=\"558\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">__name__ is &quot;report&quot;</text> <rect x=\"396\" y=\"166\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the guarded block does not</text> <text x=\"360\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Without it, the import in lesson 16 would run the whole program</text> <text x=\"360\" y=\"241\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">every time a test file said import report.</text> </svg>", "caption": "The guard is not ceremony: it is what lets one file be a program you run and a module your tests import."}
```

## What it is actually for

Not ceremony, and not style. It is what lets one file be both **a tool you run** and **a module
you import**, which is what makes it testable: lesson 16's tests import your file, and without
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
