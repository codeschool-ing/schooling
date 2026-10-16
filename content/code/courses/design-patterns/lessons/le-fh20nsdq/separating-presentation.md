---
title: Three jobs that change at different speeds
version: 1
---

**MVC is often described as three folders, `models/`, `views/` and `controllers/`, and a project
that has them is said to follow it.** The folders are a consequence. The idea underneath every
pattern in this lesson is older and simpler: a program with a screen does three different jobs, and
each job changes for a different reason. Keeping them apart means each one can change without
dragging the other two along.

The three jobs are these. The **rules**: a member may hold so many loans, a late return costs 50
cents a day. The **presentation**: what the screen shows and how it is laid out. The **input**:
turning a key press, a click or an HTTP request into something the program should do. The library
changes its rules when the committee meets, the screen when somebody redesigns it, and the input
when the desk moves from a keyboard to a browser to a phone. Three calendars.

Make `~/patterns/presentation` and work there for the whole lesson:

```sh
mkdir -p ~/patterns/presentation
cd ~/patterns/presentation
```

## A loan desk with the three jobs in one loop

Here is the desk written the way most first versions are. It reads commands from the keyboard, one
per line, and answers each one:

```python
# tangled.py
import sys

LIMIT = 2
shelf = ["B1", "B2", "B3"]
loans = {}

for line in sys.stdin:
    cmd, *args = line.split()
    if cmd == "lend":
        code, member = args
        held = [c for c, m in loans.items() if m == member]
        if code not in shelf:
            print(f"*** {code} is not on the shelf ***")
        elif len(held) >= LIMIT:
            print(f"*** {member} already has {LIMIT} loans ***")
        else:
            shelf.remove(code)
            loans[code] = member
            print(f"{code} lent to {member}. On the shelf: {', '.join(shelf)}")
    elif cmd == "return":
        shelf.append(args[0])
        del loans[args[0]]
        print(f"{args[0]} is back. On the shelf: {', '.join(shelf)}")
```

The limit is two loans so that the transcript stays short; the library's real rule is five, and
lesson 12 makes that number an invariant. `printf` types the four commands for you, so every run
of the transcript is the same:

```
ana@laptop:~/patterns/presentation$ printf 'lend B1 bia\nlend B2 bia\nlend B3 bia\nreturn B1\n' | python3 tangled.py
B1 lent to bia. On the shelf: B2, B3
B2 lent to bia. On the shelf: B3
*** bia already has 2 loans ***
B1 is back. On the shelf: B3, B1
```

It works. Now read it for where each job lives. The rule "at most two loans" is the `elif` in the
middle, sitting between two `print` calls. The layout of the shelf line is written twice, once
after a loan and once after a return, and nothing makes the two agree. The input format,
`lend B1 bia`, is unpacked on the same line that the rule reads its arguments from.

## What the tangle costs

Three requests show the price, and each one is ordinary.

**To test the rule, you have to drive the keyboard and read the screen.** There is no function to
call that answers "may Bia borrow B3?". A test has to feed text in on standard input and search the
output for asterisks, and it breaks the day somebody changes `***` to `!!`, though no rule moved.

**To add a web page, you copy the rule.** A browser sends a request, not a line on standard input,
so the loop cannot be reused. Whoever writes the page writes the limit check again, and from then on
the desk and the web have two copies of it. The committee raises the limit to five; one copy is
updated.

**To change the layout, you edit the rules' file.** Moving the shelf list onto its own line means
editing the same block that removes a book from the shelf, and the person doing the redesign now
has to understand loans to avoid breaking one.

None of this matters in a script that will never grow a second screen, and lesson 19 is honest
about that. It matters the first time a second screen, a test or a redesign arrives.

## The move every pattern here makes first

**Every pattern in this lesson starts by taking the rules out into a model that knows nothing about
screens or keyboards.** Martin Fowler calls this *separated presentation*, and it is the part they
agree on. Where they differ is in how the other two jobs are divided, and in one question that turns
out to decide most of the rest: when the state changes, who tells the screen?

- In MVC, the view watches the model and redraws itself.
- In MVP, a presenter tells a passive view exactly what to show.
- In MVVM, the view binds to properties of a view-model and updates when they change.

The next sections build each one on the same model file, so that what changes between them is only
the presentation side. The model is the next section's first program.
