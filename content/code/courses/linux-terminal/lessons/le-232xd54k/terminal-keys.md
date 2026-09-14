---
title: The keys nobody tells you about
version: 1
---

This section teaches no command. It is about a dozen keystrokes, and it is the difference between
somebody who retypes every path and somebody who is fluent.

None of it is optional knowledge. **One of these keys does something different here from what it
does in every other program you have used**, and the day you find that out by accident is a day
you lose work.

## Tab, which is the one that changes everything

Press Tab and the shell finishes what you were typing. Type enough to be unambiguous:

```
ana@vm:~/demo$ ls re
```

…press Tab, and the line becomes:

```
ana@vm:~/demo$ ls readme.txt
```

If what you typed is ambiguous, one Tab does nothing and a second Tab shows you the choices:

```
ana@vm:~/demo$ ls 
-strange        folder/         with space.txt
.hidden         readme.txt
```

Three habits follow, and they are worth building deliberately:

- **Never type a path in full.** Type three letters and press Tab. It is faster, and it cannot
  make a typo.
- **Tab is also a spell-checker.** If it does not complete, the thing you are naming is not there
  — wrong directory, wrong name, or it does not exist. You have just been told, before pressing
  enter.
- **It completes commands too**, not only files. Type `whoa` at an empty prompt and Tab will find
  `whoami`.

## The history is the second-biggest saving

| key | what it does |
|---|---|
| **↑ / ↓** | walk back and forward through the commands you have typed |
| **Ctrl+R** | search the history — start typing and it finds the most recent match; Ctrl+R again for the one before |
| `history` | print the list, numbered |
| `!!` | the previous command, re-run. Mostly seen as `sudo !!` |

The history survives closing the terminal, which surprises people. It lives in a file in your home
directory, and that is worth knowing for a reason nobody mentions at the start: **anything you
type at a prompt is written down.** A password typed as an argument to a command is now in a file.
Lesson 4 comes back to this where it matters.

## Ctrl+C is not copy

In every other program on your computer, `Ctrl+C` copies. **In a terminal it means stop**, and it
is the most important key in this section.

```
ana@vm:~$ sleep 30
^C
ana@vm:~$ echo $?
130
```

`sleep 30` should have held the prompt for half a minute. `Ctrl+C` took it back immediately. The
`^C` is the terminal showing you what you sent; the `130` is the exit status, and it is
specifically the number that means *this program was interrupted*. Section 94 of lesson 6 explains
where 130 comes from; for now it is the receipt.

**So how do you copy?** `Ctrl+Shift+C` and `Ctrl+Shift+V` in most Linux terminals, `Cmd+C` on a
Mac, and selecting text with the mouse often copies by itself. The shift is what keeps `Ctrl+C`
free for its real job.

## Ctrl+D means "that is all the input"

```
ana@vm:~$ cat
hello
hello
ana@vm:~$
```

`cat` with no file reads what you type and echoes it back — it never finishes on its own. `Ctrl+D`
on an empty line is how you say the input is over. Notice there is no `^D` on the screen and no
error: this is an ordinary, successful ending, which is why the next prompt is just there.

At an empty prompt, the same key ends the shell itself — the same meaning, applied to the shell's
own input. That is why `Ctrl+D` logs you out, and why pressing it twice by accident closes your
window.

**`Ctrl+C` and `Ctrl+D` are not two ways to do one thing.** `Ctrl+C` interrupts a program that is
running. `Ctrl+D` tells a program that is reading that there is nothing more to read. Using the
first where you need the second throws away what you typed.

## Editing the line you are on

You do not have to hold backspace. These work at the prompt, and in a great many other places
once you know them:

| key | what it does |
|---|---|
| **Ctrl+A** | jump to the start of the line |
| **Ctrl+E** | jump to the end |
| **Ctrl+U** | delete from the cursor back to the start |
| **Ctrl+K** | delete from the cursor to the end |
| **Ctrl+W** | delete the word before the cursor |
| **Alt+←  / Alt+→** | move a word at a time |

`Ctrl+U` is the one to learn first. It is how you abandon a half-typed line without running it —
and it is safer than `Ctrl+C` for that, because it leaves no doubt about whether anything ran.

## Two more, and one trap

**Ctrl+L clears the screen.** Nothing is deleted and nothing stops; the text scrolls out of view.
`clear` is the same thing as a command.

**Ctrl+Z suspends.** The program stops where it is and you get the prompt back — but *it is still
there*, paused, not finished. Section 90 of lesson 6 is about picking it back up. Until then,
know that using `Ctrl+Z` to "stop" something leaves it stopped and alive, which is not usually
what you meant.

**And Ctrl+S freezes your terminal.** Nothing you type appears. The machine looks dead. It is not:
`Ctrl+S` is an ancient key meaning *pause the output*, and it has been waiting on keyboards ever
since. The cure is `Ctrl+Q`, which resumes.

That one is here because it is the most common false alarm there is. Somebody reaches for
`Ctrl+S` to save — there is nothing to save, and no program is listening — the screen stops
responding, and they restart the machine. **Press `Ctrl+Q` first, always.**

## The short list to actually memorise

Six keys, and you will have the rest by osmosis:

1. **Tab** — complete it, and check that it exists
2. **↑** — the last command, again
3. **Ctrl+R** — find a command from last week
4. **Ctrl+C** — stop this
5. **Ctrl+U** — clear the line I am typing
6. **Ctrl+Q** — un-freeze the screen I just froze
