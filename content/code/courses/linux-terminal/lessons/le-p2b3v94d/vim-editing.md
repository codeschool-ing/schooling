---
title: Operators and motions, which is a grammar
version: 1
---

This is the section that explains why people who use vim will not stop using it.

**An edit is an operator plus a motion.** `d` is delete, `w` is a word, so `dw`
deletes a word. You do not learn commands; you learn a dozen operators and a
dozen motions, and every pair is a command that works.

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout                                                                 │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│/timeout                                              4,8           All │
└────────────────────────────────────────────────────────────────────────┘
```

That is `/timeout`, `w`, `dw` — find the line, move onto the next word, delete
a word. The `30` is gone and the cursor is at column 8.

## The operators

| | |
|---|---|
| `d` | **delete** |
| `c` | **change** — delete, and go into insert mode |
| `y` | **yank** — copy |
| `>` `<` | indent, unindent |
| `gu` `gU` | lower case, upper case |
| `=` | re-indent, if vim knows the language |

## The grammar

```
[count] operator [count] motion
```

| | |
|---|---|
| `dw` | delete a word |
| `d3w` | delete three words |
| `3dw` | the same thing — the count can go either side |
| `d$` | delete to the end of the line |
| `d0` | delete to the start |
| `dG` | delete to the end of the file |
| `dgg` | delete to the top |
| `df,` | delete up to and including the next comma |
| `ct=` | change everything up to the next `=` |

**None of those had to be memorised individually.** They are two known things
put together, and that is the entire claim.

Doubling the operator makes it act on the whole line: `dd` deletes a line, `yy`
copies one, `cc` changes one, `>>` indents one.

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│3 fewer lines                                         2,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`2G` then `3dd` — go to line 2, delete three lines. **`3 fewer lines`** is vim
telling you exactly what it did, on the line where it tells you everything.

## Text objects, which are the other half

A motion goes *from here to there*. A text object is *this whole thing,
wherever the cursor is inside it*:

| | |
|---|---|
| `iw` `aw` | **inner word**, **a word** (including the space after it) |
| `i"` `a"` | inside the quotes, and including them |
| `i(` `a(` | inside the brackets, and including them |
| `ip` `ap` | a paragraph |
| `it` `at` | an XML or HTML tag |

`ci"` — **change inside quotes** — replaces the contents of a string with the
cursor anywhere inside it. `da(` deletes a bracketed expression and its brackets.
`dap` deletes a paragraph.

**`ciw` and `ci"` are the two that change how you edit.** Nothing has to be
selected first, and the cursor does not have to be at either end.

## Small commands worth having

| | |
|---|---|
| `x` | delete the character under the cursor |
| `r` then a character | **replace** one character |
| `~` | swap the case of one character |
| `J` | **join** this line and the next |
| `.` | **repeat the last change** |
| `u` | undo |
| `Ctrl-r` | redo |

**`.` is the most valuable key in vim.** Make a change, move to the next place it
is needed, press `.`. `ciwnew<Esc>` then `n` then `.` is a targeted search and
replace where you approve each one — and it is often better than the substitute
command in the next section, because you can see each change happen.

## Yank and put

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│                                                      3,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`2G`, `yy`, `p` — go to line 2, copy it, put it below. Line 2 is now there twice.

| | |
|---|---|
| `p` | put **after** the cursor, or below the line |
| `P` | put before, or above |
| `yy` `3yy` | copy one line, three lines |

**Deleting yanks too.** `dd` puts the line in the same place `yy` does, so
`dd` then `p` moves a line down, and `ddP` puts it back. There is no separate
clipboard for cut and copy.

## Undo is a tree, not a stack

`u` undoes, `Ctrl-r` redoes, and vim says what it did:

```
┌────────────────────────────────────────────────────────────────────────┐
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
│~                                                                       │
│1 more line; before #2  1 second ago                  1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

Two `dd`s and then `u`. **`1 more line; before #2  1 second ago`** — one line came
back, you are now before change number 2, which was a second ago.

`:undolist` shows the numbered changes, `:earlier 5m` goes back five minutes, and
`g-` and `g+` walk the tree rather than the line. Those are more than you need
today and are the reason the message is worded that way.

## One undo per insert

`u` undoes a whole **insert session**, not a character. Type a paragraph without
pressing `Esc` and one `u` removes all of it.

**So press `Esc` at natural stopping points.** It costs nothing and it makes undo
granular, which is the difference between losing a word and losing a paragraph.
