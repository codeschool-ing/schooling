---
title: Files, buffers and windows — and getting out
version: 1
---

## Writing and quitting

| | |
|---|---|
| `:w` | write |
| `:w name` | write to a different file, and keep editing this one |
| `:q` | quit |
| `:wq` or `:x` | write and quit |
| `:q!` | quit, **throwing away** unsaved changes |
| `:wa` `:qa` `:wqa` | all open files |
| `ZZ` | `:wq`, from normal mode |
| `ZQ` | `:q!`, from normal mode |

`:x` differs from `:wq` in one way: it does not write if nothing changed, so it
does not touch the modification time. On a file something else is watching, that
matters.

## `:w` tells you what it wrote

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout sixty                                                           │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│"server.conf" 6L, 104B written                        4,13          All │
└────────────────────────────────────────────────────────────────────────┘
```

It opened as `6L, 101B`. It wrote `6L, 104B`. **Six lines both times — nothing was
deleted** — and three bytes more, because `30` became `sixty`.

Reading that line takes a second and catches the edit you did not mean to make.

## New files

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│"brandnew.txt" [New]                                      0,0-1         All │
└────────────────────────────────────────────────────────────────────────────┘
```

**`[New]`** — the file does not exist yet, and it will not exist until you `:w`.
Opening a file by the wrong name and finding it empty is usually this, and the
marker is the tell.

## When you cannot write

```
┌────────────────────────────────────────────────────────────────────────────┐
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│E45: 'readonly' option is set (add ! to override)                           │
│Press ENTER or type command to continue                                     │
└────────────────────────────────────────────────────────────────────────────┘
```

That is `vim /etc/hostname` as an ordinary user, an edit, and `:w`. Vim opened
the file read-only — it warned `W10: Warning: Changing a readonly file` the
moment the edit was made — and refuses to write.

**`:w!` will get past the `readonly` option and then fail on the permission**,
because the file is root's and you are not (lesson 4 section 02). The real answers
are:

```sh
sudoedit /etc/hostname        # edits a copy as you, installs it as root
sudo vim /etc/hostname        # runs the whole editor as root
:w !sudo tee %                # the famous trick, from inside vim
```

**`sudoedit` is the right one** and is in section 13. `sudo vim` runs an editor
with a configuration file and plugins as root, which is a larger surface than
the job needs.

## Several files at once

```
┌────────────────────────────────────────────────────────────────────────────┐
│timeout 30                                                                  │
│log_level info                                                              │
│log_file /var/log/app.log                                                   │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│:ls                                                                         │
│  1 %a   "server.conf"                  line 1                              │
│  2      "notes.txt"                    line 0                              │
│Press ENTER or type command to continue                                     │
└────────────────────────────────────────────────────────────────────────────┘
```

`vim server.conf notes.txt` opens two **buffers**. `:ls` lists them, and the
markers matter: `%` is the one in this window, `a` is active.

| | |
|---|---|
| `:e file` | open another file |
| `:bn` `:bp` | next, previous buffer |
| `:b2` or `:b notes` | go to a buffer by number or by part of its name |
| `:bd` | close a buffer |
| `:ls` | list them |

**A buffer is a file in memory; a window is a view of one.** Closing a window
does not close the buffer, which is why `:q` sometimes leaves you in vim.

## Splits

```
┌────────────────────────────────────────────────────────────────────────────┐
│the first line                                                              │
│the second line                                                             │
│the third line                                                              │
│~                                                                           │
│~                                                                           │
│~                                                                           │
│notes.txt                                                 1,1            All│
│# the server configuration                                                  │
│listen 8080                                                                 │
│workers 4                                                                   │
│timeout 30                                                                  │
│log_level info                                                              │
│server.conf                                               1,1            Top│
│"notes.txt" 3L, 46B                                                         │
└────────────────────────────────────────────────────────────────────────────┘
```

`:sp notes.txt` — **two windows, each with its own status line** giving the
filename, the cursor position, and how much of the file is visible: `All` for
the three-line file, `Top` for the six-line one in a five-line window.

| | |
|---|---|
| `:sp file` | split horizontally |
| `:vs file` | split vertically |
| `Ctrl-w` then `w` | cycle between windows |
| `Ctrl-w` then `h` `j` `k` `l` | move to the window in that direction |
| `Ctrl-w` then `q` | close this window |
| `:only` | close every window but this one |

**`Ctrl-w` is the window prefix**, and every window command starts with it.

## Reading and running

```sh
:r file           # read a file in below the cursor
:r !date          # read the output of a command in
:!ls -l           # run a command, show the output, come back
:%!sort           # pipe the whole buffer through sort and replace it
:%!python3 -m json.tool    # reformat the buffer as JSON
```

**`:%!command` is vim's best-kept feature.** The buffer goes to the command's
standard input and the output replaces it — so every filter in lesson 8 is
available to you on the file you are editing, without saving it first:

```
┌────────────────────────────────────────────────────────────────────────┐
│apple                                                                   │
│banana                                                                  │
│cherry                                                                  │
│pear                                                                    │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│4 lines filtered                                      1,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

Four unsorted lines, `:%!sort`, and **`4 lines filtered`**.

## One thing that will bite you

```
┌────────────────────────────────────────────────────────────────────────┐
│pear                                                                    │
│list.txtY-list.txtm-list.txtd                                           │
│apple                                                                   │
│cherry                                                                  │
│banana                                                                  │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│                                                      2,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

That was `:r !date +%Y-%m-%d`, in a file called `list.txt`.

**On vim's command line, `%` means the current filename.** So `+%Y-%m-%d` became
`+list.txtY-list.txtm-list.txtd`, `date` was given nonsense, and vim read the
nonsense in. Escape it as `\%`, or quote it — and this is the same `%` that makes
`:w !sudo tee %` work.

