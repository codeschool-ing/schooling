---
title: Emacs, honestly and briefly
version: 1
---

Emacs is the third editor, and the honest framing is: you are unlikely to meet
it by accident. It is not installed by default on any mainstream distribution,
no tool opens it unless you asked for it, and nothing in this course requires it.

It is in this lesson because it is genuinely a third idea, and because if you
inherit a machine where somebody set `EDITOR=emacs` you should not be lost.

```
ana@vm:~/work/edit$ emacs -nw server.conf
┌────────────────────────────────────────────────────────────────────────────┐
│File Edit Options Buffers Tools Conf Help                                   │
│# the server configuration                                                  │
│listen 8080                                                                 │
│workers 4                                                                   │
│timeout 30                                                                  │
│log_level info                                                              │
│log_file /var/log/app.log                                                   │
│                                                                            │
│                                                                            │
│                                                                            │
│                                                                            │
│                                                                            │
│-UU-:---  F1  server.conf    All   L1     (Conf[Space]) --------------------│
│For information about GNU Emacs and the GNU system, type C-h C-a.           │
└────────────────────────────────────────────────────────────────────────────┘
```

**`-nw` means no window** — run in this terminal rather than opening a graphical
one. Without it, on a machine with a display, emacs opens a separate window; on
a machine over `ssh` it says it cannot and falls back.

Three parts to that screen. The **menu bar** at the top, which is real and
usable with `F10`. The **mode line** near the bottom: `server.conf`, `All`
(the whole file is visible), `L1` (line 1), and `(Conf[Space])` — the major mode
emacs picked from the filename. And the **echo area** at the very bottom, which
is where prompts and messages appear.

The `-UU-` and `**` at the left of the mode line are the buffer's state: `**`
means unsaved changes, which the screenshot below shows.

## No modes, and a different idea instead

Emacs types when you type, like nano. Commands are **key chains** built from two
modifiers:

| | |
|---|---|
| `C-x` | Control and x |
| `M-x` | Meta and x — Alt, or `Esc` then `x` |

`M-` is `Esc` followed by the key on a terminal that does not send Alt properly,
which is most of them over `ssh`.

## The minimum

| | |
|---|---|
| `C-x C-s` | **save** |
| `C-x C-c` | **quit** |
| `C-x C-f` | open a file |
| `C-g` | **cancel** whatever you started. The `Esc` of emacs |
| `C-s` | search forward, incrementally |
| `C-r` | search backward |
| `C-_` or `C-/` | undo |
| `C-k` | kill to end of line |
| `C-y` | yank — paste |
| `C-a` `C-e` | start, end of line |

**`C-g` is the one to have.** Emacs is full of multi-key commands, and `C-g`
abandons the one you are half way through.

`C-s` is worth noticing for a different reason: it is search here, and it is the
terminal's *stop output* elsewhere (lesson 1 section 08). Emacs takes the key
over, which works — and is why an emacs user and a nano user disagree about what
`C-s` does.

## Leaving

```
┌────────────────────────────────────────────────────────────────────────────┐
│File Edit Options Buffers Tools Conf Help                                   │
│hello# the server configuration                                             │
│listen 8080                                                                 │
│workers 4                                                                   │
│timeout 30                                                                  │
│log_level info                                                              │
│log_file /var/log/app.log                                                   │
│                                                                            │
│                                                                            │
│                                                                            │
│                                                                            │
│-UU-:**-  F1  server.conf    All   L1     (Conf[Space]) --------------------│
│Save file /home/ana/work/edit/server.conf? (y, n, !, ., q, C-r, C-f, d or C\│
│-h)                                                                         │
└────────────────────────────────────────────────────────────────────────────┘
```

`hello` was typed and then `C-x C-c`. **Emacs asks about each unsaved buffer by
name**, with nine possible answers — `y`, `n`, `!` for all of them, `d` to see a
diff first — and it will not exit until every one is dealt with.

The `\` at the end of the prompt line is emacs saying the line is longer than the
screen and continues.

## What it is actually for

Everything above makes emacs look like a heavier nano. It is not; it is a Lisp
environment with an editor in it, and the reason people use it is the things that
run inside it:

| | |
|---|---|
| `M-x shell`, `M-x eshell` | a shell, in a buffer |
| `M-x dired` | a file manager, in a buffer |
| Magit | a git interface that people switch editors for |
| Org mode | notes, outlines, scheduling, and literate documents |
| `M-x tramp` | edit files on a remote machine **as if they were local** |

That last one is section 14's subject, and it is the one thing in this list
where emacs is straightforwardly better than the alternatives.

## Where it leaves you

**If somebody hands you an emacs, you need three keys**: `C-g` to cancel,
`C-x C-s` to save, `C-x C-c` to leave. That is the whole of what this section is
for.

**If you want to learn it properly**, `C-h t` opens the built-in tutorial, which
is emacs' `vimtutor` and is as good. It is a real decision though: emacs is an
environment, and the people who are happy in it did not learn an editor, they
moved in.
