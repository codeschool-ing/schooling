---
title: The library with no annotations, and the ignore with a reason
version: 1
---

```python
import yaml
```

```sh
error: Library stubs not installed for "yaml"  [import-untyped]
note: Hint: "python3 -m pip install types-PyYAML"
note: (or run "mypy --install-types" to install all missing stub packages)
```

**Read the hint.** Hundreds of libraries have a `types-…` package on PyPI — stub files, written
and maintained by other people, that say what the library's functions take and return. Install it
into the same environment and the error goes away with real types behind it, not a silence.

## Two different messages

```sh
error: Library stubs not installed for "yaml"      [import-untyped]
error: Cannot find implementation or library stub for module named "wibblelib"  [import-not-found]
```

The first means the library is installed and has no types. The second means the checker cannot
find the module at all — usually a typo, a missing install, or a `PYTHONPATH` the checker does
not share.

Turning on `ignore_missing_imports` globally silences both, which is why it belongs in a
per-module override rather than at the top.

## `py.typed`

A library that ships its own annotations puts an empty file called `py.typed` in its package
directory. Without it, the annotations in the source are ignored even though they are right
there — the marker is the author saying "these are meant to be checked". If you publish a
package, that empty file is what makes your annotations useful to everybody else.

## The ignore comment, and the two ways it goes wrong

```python
value = untyped_lib.fetch()  # type: ignore[no-any-return]  # the stub lies about the return
```

Name the code. A bare `# type: ignore` silences **every** error on that line, including the one
that appears next year when somebody edits it.

```python
n: int = "a"  # type: ignore[arg-type]
```

```sh
error: Incompatible types in assignment ...  [assignment]
note: Error code "assignment" not covered by "type: ignore" comment
```

The wrong code does not silence the error, and the note says so by name. That is the good case:
a narrow ignore that stops matching starts reporting again.

## And the ignore that outlived its reason

```sh
mypy --warn-unused-ignores app/
```

```sh
error: Unused "type: ignore" comment  [unused-ignore]
```

The stub was fixed, the library grew annotations, the code changed — and the comment is still
there, silencing nothing and lying about the state of the file. This flag is inside `--strict`,
and it is worth turning on long before the rest of it.
