---
title: What you ask for, and the lock compiled from it
version: 1
---

Lesson 5's `requirements.txt` mixes two different things in one flat list: **what linkbox asks for**
(Flask and gunicorn) and **what those happen to need today** (six others). Nobody can tell from the
file which is which, so nobody can tell whether `markupsafe` may be removed, or why `packaging` is in
the image at all. The fix is two files with two jobs.

- **`requirements.in`** says what the service asks for, as ranges a person chose and can defend.
- **`requirements.txt`** is compiled from it by a tool: every package the ranges resolve to, at one
  exact version, with the hash of every file that version publishes, and a comment saying who
  pulled each one in. Nobody edits it by hand.

Save the first as `requirements.in`:

```
# What linkbox asks for, and nothing it needs only because something else
# does. requirements.txt is compiled from this file, with every version
# pinned and the hash of every file beside it:
#
#   uv pip compile requirements.in --generate-hashes \
#     --exclude-newer 2026-10-16 -o requirements.txt
flask>=3.1.3,<4
gunicorn>=26.2,<27
```

And what the tests ask for, compiled the same way, as `requirements-dev.in`:

```
# What the tests need, compiled into requirements-dev.txt the same way:
#
#   uv pip compile requirements-dev.in --generate-hashes \
#     --exclude-newer 2026-10-16 -o requirements-dev.txt
pytest>=9.0.3,<10
```

The lower bounds are the versions lesson 5 moved to past their advisories, so no compile can go back
below them. The upper bounds stop at the next major version, where an update becomes a decision for a
person.

### The compiler keeps what it finds

`uv pip compile` resolves the ranges and writes the lock. It has one behaviour worth meeting before it
surprises you: **when the output file already exists, it keeps the versions already pinned there** if
they still satisfy the ranges. Run against lesson 5's file, still in place:

@@CAPTURE keeps@@

gunicorn moved, because `>=26.2` forced it. `click` and `markupsafe` stayed at lesson 5's versions,
because they still fit. That is a feature: a lock changes as little as it can, so a review of the
change reads only what moved. Here it is not what is wanted, because this is the first compile and
the old file was never a lock. So both old files go, and the compile starts clean, with the hashes:

@@CAPTURE compile@@

`--generate-hashes` writes, under every pin, the SHA-256 of every file PyPI publishes for that
version: a wheel per platform and Python version, and the source archive. `markupsafe` alone
publishes dozens, which is most of the 169 hashes in `requirements.txt`. **A hash pins the bytes, not
only the version**: if somebody replaced a file on the index, or a mirror served a different one, the
install would refuse it, as lesson 12 showed with a hash that did not match. `--exclude-newer` is the
date the next section is about.

### Install only what the lock names

The lock is only a lock if every install honours it. Save the test stage as `ci/test.sh`:

```sh
# The unit tests, in a fresh virtual environment with the pinned
# dependencies, each one checked against its hash before it is installed.
set -euo pipefail
uv venv -q .venv
uv pip install -q --require-hashes -r requirements.txt -r requirements-dev.txt
.venv/bin/python -m pytest -q
```

`--require-hashes` makes the installer refuse any package that has no hash in the file, which also
means a dependency nobody pinned cannot slip in: the tests' environment is the lock, or nothing.

@@CAPTURE tests@@

### Where `packaging` went

The compiled `requirements.txt` has no `packaging` in it, and the reason is the update, not the
compile. The same ranges with gunicorn held below 23 compile it right back, with the comment that
says who wanted it:

@@CAPTURE packaging@@

**The lock now says why every package is there.** `# via gunicorn` is the answer to the question
lesson 13 could only raise. The development lock still carries `packaging`, because pytest needs it,
and that one never reaches the image.

@@FIGURE lock@@
