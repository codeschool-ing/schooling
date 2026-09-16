---
title: Modes, which is the one idea
version: 1
---

Everything confusing about vim comes from one design decision, and once you have
it the rest is vocabulary.

**In every other editor, the keyboard types. In vim, the keyboard types only
when you are in insert mode.** The rest of the time the letter keys are
commands.

That is why typing `hello` into a freshly opened vim moves the cursor around and
deletes something: `h` is left, `e` is end-of-word, `l` is right, and the second
`l` is right again, and `o` opens a new line — which does finally put you in
insert mode, which is why the confusion usually ends with a stray blank line.

## The modes you will use

| | how you get there | how you leave |
|---|---|---|
| **normal** | `Esc`, from anywhere | you do not — this is home |
| **insert** | `i` `a` `o` `O` `I` `A` | `Esc` |
| **visual** | `v` `V` `Ctrl-v` | `Esc` |
| **command-line** | `:` `/` `?` | `Enter`, or `Esc` to abandon |

**Normal mode is home.** When you do not know where you are, press `Esc`. It is
harmless in normal mode — it beeps or flashes — and it gets you there from
anywhere else.

Vim opens in normal mode. It is the only editor that does, and it is the source
of the entire joke.

## How you know which one you are in

```
ana@vm:~/work/edit$ vim server.conf
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
│"server.conf" 6L, 101B                                1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

**The bottom line is the whole of vim's user interface.** Left: what just
happened — here, the file it opened, six lines, 101 bytes. Right: the cursor,
line 1 column 1, and `All`, meaning the whole file fits on the screen.

The `~` lines are not part of the file. They mark where the file ends and the
screen keeps going.

Press `i`:

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
│-- INSERT --                                          1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

**`-- INSERT --`.** That is the only difference on the screen, and it is the
thing to look at when you are not sure whether your keystrokes are going into
the file.

`Esc`, and it goes away. A mode with no announcement is normal mode.

And visual:

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
│-- VISUAL LINE --                           3         3,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`V` then `jj` — `-- VISUAL LINE --`, and the `3` in the middle is how many lines
are selected. (On a real terminal those three lines are highlighted; a page like
this cannot show colour, so the count is the part to read.)

## The six ways into insert mode

They differ by *where* they put you, and picking the right one saves a motion:

| | |
|---|---|
| `i` | **insert** before the cursor |
| `a` | **append** after the cursor |
| `I` | insert at the first non-blank of the line |
| `A` | append at the **end** of the line |
| `o` | **open** a new line below, and go there |
| `O` | open a new line above |

**`A` and `o` are the two you will use most**, because the two things you
usually want are "add to the end of this line" and "add a new line".

## `Esc` is far away

On a keyboard where `Esc` is where `Caps Lock` should be, this is fine. On a
laptop with a touch bar it is not.

**`Ctrl-[` is `Esc`.** Not a substitute — the same byte, 27, which is why the
terminal cannot tell them apart (lesson 1 section 08). Every vim user who does
not remap their keyboard uses it.

`Ctrl-c` also leaves insert mode and is not quite the same: it skips some of what
`Esc` does on the way out, which matters for a handful of plugins and never for
anything in this lesson.
