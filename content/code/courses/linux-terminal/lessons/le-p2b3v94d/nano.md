---
title: Nano, which is the whole of nano
version: 1
---

This section is not an introduction to nano. It is nano.

```
ana@vm:~/work/edit$ nano notes.txt
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt                             │
│the first line                                                          │
│the second line                                                         │
│the third line                                                          │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                            [ Read 3 lines ]                            │
│^G Help       ^O Write Out  ^W Where Is   ^K Cut        ^T Execute      │
│^X Exit       ^R Read File  ^\ Replace    ^U Paste      ^J Justify      │
└────────────────────────────────────────────────────────────────────────┘
```

**Type, and it types.** The arrow keys move. Backspace deletes. There are no
modes. If you have used any text box in any program since 1990, you already know
how to use nano.

And the two lines at the bottom are the manual. `^` means Control, so `^X` is
Control-X.

## The ten that matter

| | |
|---|---|
| `^O` | **write out** — save. It asks you for the filename; press Enter |
| `^X` | **exit**. If there are unsaved changes it asks |
| `^W` | **where is** — search |
| `^\` | **replace** |
| `^K` | **cut** the current line |
| `^U` | **paste** it back |
| `^C` | show the current line and column |
| `^_` | go to a line number |
| `^G` | help, which is the same list with explanations |
| `M-U` | undo. `M-` means Alt, or Escape then the key |

`^O` for save is the one people get wrong, because every other program uses
`^S`. On this version `^S` does save:

```
│                           [ Wrote 3 lines ]                            │
```

But `^S` is also the terminal's own *stop output* key from section 8, and on a
setup where nano has not taken it over, pressing it freezes your screen until
you press `^Q`. **`^O` works everywhere**, and is the one to have in your
fingers.

`M-U` really is undo, and says what it undid:

```
│                           [ Undid addition ]                           │
```

## Searching

```
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt                             │
│the first line                                                          │
│the second line                                                         │
│the third line                                                          │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│Search: second                                                          │
│^G Help       M-C Case Sens M-B Backwards ^P Older      ^T Go To Line   │
│^C Cancel     M-R Reg.exp.  ^R Replace    ^N Newer                      │
└────────────────────────────────────────────────────────────────────────┘
```

**The bottom two lines changed.** That is how nano works throughout: the shortcut
bar always shows what is available *right now*, so the prompt for a search offers
case sensitivity, backwards, regular expressions and the search history.

`^C` cancels, here and everywhere. Press it when you are lost.

## Leaving

```
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt *                           │
│a new word the first line                                               │
│the second line                                                         │
│the third line                                                          │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│Save modified buffer?                                                   │
│ Y Yes                                                                  │
│ N No           ^C Cancel                                               │
└────────────────────────────────────────────────────────────────────────┘
```

**`^X`, then `Y` or `N`.** That is the answer to the question this lesson's
video opens with, and it is why nano exists.

Note the `*` after the filename in the title bar — that is nano saying the buffer
has unsaved changes, and it appears the moment you type anything.

## Two flags worth knowing

```
ana@vm:~/work/edit$ nano -l +2 notes.txt
┌────────────────────────────────────────────────────────────────────────┐
│  GNU nano 7.2                    notes.txt                             │
│ 1 the first line                                                       │
│ 2 the second line                                                      │
│ 3 the third line                                                       │
│ 4                                                                      │
│                                                                        │
│                                                                        │
│                                                                        │
│                                                                        │
│                            [ Read 3 lines ]                            │
│^G Help       ^O Write Out  ^W Where Is   ^K Cut        ^T Execute      │
│^X Exit       ^R Read File  ^\ Replace    ^U Paste      ^J Justify      │
└────────────────────────────────────────────────────────────────────────┘
```

`-l` numbers the lines, `+2` opens at line 2, and `-w` turns off wrapping.

**`-w` is the important one.** By default nano hard-wraps long lines *in the
file* — it inserts real newlines — and on a configuration file with a long value
that is a change you did not make on purpose. Modern versions default to off, and
older ones did not.

`~/.nanorc` turns it on permanently:

```sh
set nowrap
set linenumbers
set tabstospaces
```

## What nano cannot do

It has no macros, no split windows, no plugin ecosystem and no language
awareness beyond syntax colouring. Editing a thousand-line file in it is
unpleasant, and editing a codebase in it is not something anybody does.

**None of that is what you opened it for.** For "change one line in a
configuration file over ssh" it is complete, it took ten minutes to learn, and
the shortcuts are on the screen.

The next seven sections are vim, for the machines where nano is not installed —
and because there is a real argument for it that this one has not made.
