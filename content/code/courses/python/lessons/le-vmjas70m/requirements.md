---
title: `requirements.txt`, and why `pip freeze` does not write one
version: 2
---

```sh
# requirements.txt
requests==2.31.0
```

```sh
python -m pip install -r requirements.txt
```

A text file naming what the project needs, one per line, with the same specifiers as the command
line. Comments start with `#`, and `-r other.txt` includes another file.

## What `pip freeze` gives you instead

```sh
$ python -m pip freeze
certifi==2026.7.22
charset-normalizer==3.5.1
idna==3.20
requests==2.31.0
urllib3==2.8.0
```

**Five lines, and the project asked for one of them.** `freeze` prints what is installed, pinned
exactly, in alphabetical order, with no distinction between what you chose and what came along
with it.

That output is useful and it is not a requirements file, for three reasons:

- **Nothing says which packages are yours.** In a year, nobody can tell whether `idna` is a
  dependency of the project or a leftover of something uninstalled.
- **Removing a package leaves its dependencies behind**, and `freeze` keeps printing them, so the
  file grows and never shrinks.
- **It pins things you have no opinion about.** A security fix in `urllib3` now needs an edit to
  your requirements file.

## `freeze > requirements.txt` is how it goes wrong

It is the first thing everybody does, it works, and what it produces is a file nobody can read
six months later. The list grows every time somebody adds a library, never shrinks, and the day a
transitive pin blocks an upgrade, working out which line may be deleted takes an afternoon.

## Write it by hand

```sh
# requirements.txt — what this project asks for
requests==2.31.0        # HTTP; pinned, 2.32 changed the retry behaviour
pandas~=2.2.0           # tables; patch releases are fine
```

One line per direct dependency, with the version you actually tested against, and a comment where
the pin is not obvious. It is a short file, it stays short, and it says something.

## Two files, when there are development tools

```sh
# requirements.txt
requests==2.31.0

# requirements-dev.txt
-r requirements.txt
pytest==9.0.2
ruff==0.15.8
```

`pytest` is not something the application needs to run, and installing it in production ships a
test framework to a server. The `-r` on the first line means the development file is the whole
set.
