---
title: Moving, without touching the arrow keys
version: 1
---

The arrow keys work. Use them for a week and then stop, because every motion in
this section is also an **argument to an operator** in the next one, and that is
where vim stops being a worse notepad.

## Characters and lines

```
      k
   h     l
      j
```

| | |
|---|---|
| `h` `l` | left, right |
| `j` `k` | down, up |
| `0` | the very start of the line |
| `^` | the first non-blank character |
| `$` | the end of the line |

`j` for down is the only one that needs a mnemonic: it is the letter with a
descender, hanging below the line.

`^` and `0` differ on an indented line, and `^` is almost always the one you
want.

## Words

| | |
|---|---|
| `w` | forward to the start of the next **word** |
| `b` | back to the start of the previous word |
| `e` | forward to the **end** of this word |
| `W` `B` `E` | the same, but a "word" is anything without spaces |

**The capital versions treat punctuation as part of the word**, which is what
you want for a filename or a URL: `w` on `/var/log/app.log` stops at every
slash and dot; `W` jumps the whole thing.

## Lines, screens and the file

| | |
|---|---|
| `gg` | the first line |
| `G` | the **last** line |
| `42G` or `:42` | line 42 |
| `Ctrl-d` `Ctrl-u` | half a screen down, up |
| `Ctrl-f` `Ctrl-b` | a whole screen forward, back |
| `H` `M` `L` | the **high**, **middle** and **low** line of the screen |
| `{` `}` | back and forward a paragraph — a block of non-blank lines |
| `%` | to the matching bracket |

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│"server.conf" 6L, 101B                                6,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

That is `G`. **Nothing on the screen changed except the numbers on the right** —
`6,1` instead of `1,1`. Vim moved the cursor and said so in the only place it
says anything.

`%` is worth more than it looks: put the cursor on a `{` and press it, and you go
to the matching `}`. In a configuration file with nested blocks, that is how you
find out where a block ends without counting.

## `f`, the one that changes how you move

`f` means **find**, on this line:

| | |
|---|---|
| `fx` | forward to the next `x` on this line |
| `Fx` | backward to the previous `x` |
| `tx` | forward to just before the next `x` |
| `;` | repeat the last `f`, `t`, `F` or `T` |
| `,` | repeat it backwards |

`f=` on a configuration line puts the cursor on the equals sign in two
keystrokes. `f/` walks you along a path one slash at a time with `;`.

**This is the motion that separates people who move around vim from people who
hold down `l`.**

## Marks, and the two you get free

```sh
ma        # set mark a here
'a        # jump to the line of mark a
`a        # jump to the exact position of mark a
```

Two marks are set for you and are worth knowing:

| | |
|---|---|
| `` `` `` | where you were before the **last jump**. Press it twice to toggle |
| `` `. `` | where you made the **last change** |
| `` `" `` | where you were when you last closed this file |

**`` `` `` is the one to remember.** You searched, landed somewhere, looked at
it, and now want to be back where you were: two backticks.

And `` `" `` is why vim sometimes opens a file with the cursor in the middle —
it remembered, from its `viminfo` file, and it is a feature rather than a fault.

## Counts

**Every motion takes a number in front of it**, and it means "do that many
times":

```sh
5j        # five lines down
3w        # three words forward
d2w       # delete two words — the next section
```

`5j` is not a shortcut for pressing `j` five times in the sense of saving
keystrokes; it is the grammar the whole editor is built on, and the next section
is where it pays.
