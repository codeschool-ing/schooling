---
title: Release 1.1
version: 1
---

Rui has fixed two of the defects you found in boxoffice 1.0: six tickets refused (lesson 4) and
the 25% discount for a member booking five or more (lesson 5). **In a team, a tester receives a new
build** as a package, a deployment to the test environment or a link to download. Here the build
is three edits to `boxoffice.py`, and you make them yourself, exactly as Rui wrote them. This
section is the release; the next one checks it.

## The release notes

A build arrives with a note saying what changed. This is Rui's:

> **boxoffice 1.1**
>
> Fixed: an order of six tickets was refused with "You can book 1 to 6 tickets". Six is accepted
> now.
>
> Fixed: a member booking five or more tickets got 25% off. Discounts no longer add up and the
> largest one applies, so the order gets 15%. `discount` was rewritten to do this.
>
> Known, not fixed in this release: a tickets field that is not a number still answers with an
> error page (lesson 4), and a used order can still be refunded (lesson 5).

**Release notes are a claim, and a tester reads them as one.** They say what the developer meant to
change. They cannot list what changed by accident, because nobody writes down a side effect they
did not notice. Read as a tester, these notes give you three things:

- two fixes, each with a defect report behind it, which are the sanity checks of the next section;
- one sentence about where the change went: `discount`, the function that decides every price,
  was rewritten rather than patched. Risk A of lesson 1, a wrong price, has just become more likely;
- two known defects, which are still open and need no second report when you meet them again.

## Keep 1.0 first

Before changing the program, keep a copy of the version you have. Stop boxoffice with Ctrl-C in its
terminal, and in `~/boxoffice`:

```sh
cp boxoffice.py boxoffice-1.0.py
```

On Windows without WSL, copy the file in File Explorer and rename the copy `boxoffice-1.0.py`.
Lesson 10 runs the two versions side by side, because the question "did this work before?" is only
answered by a build that still exists.

## The three edits

Open `boxoffice.py` in your editor. Each edit is a pair of blocks: find the first block in the file
with the editor's Find (Ctrl+F, or Cmd+F on a Mac), select all of it and replace it with the second
block. Every first block appears in the file exactly once. Copy each block with the button on it
rather than typing it, and keep its indentation exactly as it is: Python reads indentation as
structure, which is the `IndentationError` of lesson 1 section 05.

You do not need to understand these lines to test the result. Most testers never see the code of a
release, and what follows tests 1.1 by its behaviour alone.

**Edit 1, the version number.** Find this line:

```python
VERSION = "1.0"
```

and replace it with:

```python
VERSION = "1.1"
```

**Edit 2, the discount rule.** Find the whole function, ten lines:

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    if student:
        return 50
    off = 0
    if member:
        off += 10
    if tickets >= 5:
        off += 15
    return off
```

and replace it with these three:

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    return max(10 if member else 0, 15 if tickets >= 5 else 0)
```

**Edit 3, the quantity check.** Find this line, inside `book`, further down:

```python
    if not 1 <= quantity < 6:
```

and replace it with:

```python
    if not 1 <= quantity <= 6:
```

Save the file. Nothing changes in a running application until it starts again, because Python reads
the file once, when it starts; the next section starts it and checks what you made.

If the program refuses to start after the edits, read its error from the bottom, as lesson 1
section 05 showed: the last line says what is wrong and the lines above it say where. The quickest
repair is to copy `boxoffice-1.0.py` back over `boxoffice.py` and make the three edits again, which
is one more reason to keep the copy.
