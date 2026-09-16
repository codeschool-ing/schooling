---
title: Getting out, and the four screens that stop you
version: 1
---

This section is the one to read twice. Everything in it happens when you are in a
hurry.

## The four commands

| | |
|---|---|
| `Esc` | get to normal mode. **First, always** |
| `:q!` | leave, throwing away changes |
| `:wq` | save and leave |
| `u` | undo |

**`Esc` then `:q!`** is the answer to "I am stuck in vim". It works from insert
mode, from visual mode, from a half-typed command. It throws away your changes,
which is what you want when you did not mean to make any.

If `Esc` does not seem to work, you are probably in the middle of a multi-key
command — press it twice.

## Screen one: it will not let you quit

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
│E37: No write since last change (add ! to override)                     │
│Press ENTER or type command to continue                                 │
└────────────────────────────────────────────────────────────────────────┘
```

**`E37` is vim protecting you**, not vim being difficult. You changed something
and asked to leave without saving.

| | |
|---|---|
| `:wq` | you meant to keep it |
| `:q!` | you did not |

Notice the file lost a character — the top of the screen starts at `listen`,
because the two-line message pushed the view down, and the `#` line is above it.
The screen scrolling is not the file changing.

## Screen two: `Press ENTER`

Any message that is too long, or any command that produced output, ends with
`Press ENTER or type command to continue`. **Press Enter.** It is not a prompt
with consequences; vim is waiting for you to have read the line.

## Screen three: the swap file

```
┌────────────────────────────────────────────────────────────────────────────┐
│E325: ATTENTION                                                             │
│Found a swap file by the name ".server.conf.swp"                            │
│          owned by: ana   dated: Tue Sep 15 11:59:56 2026                   │
│         file name: ~ana/work/edit/server.conf                              │
│          modified: YES                                                     │
│         user name: ana   host name: vm                                     │
│        process ID: 18031                                                   │
│While opening file "server.conf"                                            │
│             dated: Tue Sep 15 11:59:54 2026                                │
│                                                                            │
│(1) Another program may be editing the same file.  If this is the case,     │
│    be careful not to end up with two different instances of the same       │
│    file when making changes.  Quit, or continue with caution.              │
│-- More --                                                                  │
└────────────────────────────────────────────────────────────────────────────┘
```

That is real: a vim was opened, a line was added, and the process was killed.
This is what the next vim shows.

**Vim keeps a swap file while you edit**, so that if it dies your work is not
gone. Finding one on startup means one of two things, and the screen tells you
which:

| | |
|---|---|
| `process ID: 18031` **still running** | somebody else has this file open. Press `q` and go and ask |
| that process is gone | vim or the machine died. Your unsaved work is in the swap file |

Press Enter past the `-- More --` and the choices appear. The ones that matter:

| | |
|---|---|
| `r` | **recover** — load what was in the swap file |
| `e` | edit anyway, ignoring it |
| `q` | quit. **The safe one if you are not sure** |
| `d` | delete the swap file |

**The right sequence when the work was yours and the editor died:** press `r`,
look at what came back, save it somewhere, and then `:q` and delete the swap
file — vim will not do that for you, and until it is gone you get this screen
every time.

```sh
ls -la .server.conf.swp        # they are hidden, and named after the file
rm .server.conf.swp
```

## Screen four: the terminal, not vim

Sometimes vim is fine and the terminal is not. Lesson 1 section 08's two cases:

| | |
|---|---|
| nothing appears when you type | you pressed `Ctrl-s`. Press `Ctrl-q` |
| vim exited but the terminal is a mess | `reset`, or `stty sane` |

**`Ctrl-s` is the one that looks exactly like a hung editor**, and it is a
terminal feature from the era of paper.

## Two ways to lose work that are not vim's fault

**Editing a file that something else rewrites.** A config manager, a deploy, a
service that rewrites its own file. Vim warns on write — `WARNING: The file has
been changed since reading it!!!` — and it is a prompt you have to read rather
than dismiss.

**Editing the wrong copy.** `sudo vim` on a file, then finding your change is
not there, because you opened `/etc/nginx/nginx.conf` and the running one is
`/etc/nginx/sites-enabled/default`. Not an editor problem, and the most common
way an edit "does not take".

## The card

```
Esc            get to normal mode
:q!            leave, discard changes
:wq            save and leave
u              undo
Ctrl-r         redo
/text  n       search, next
dd  yy  p      delete a line, copy a line, paste
i  A  o        insert here, at end of line, on a new line
:set paste     before pasting anything
```

Nine lines. If vim is not your editor, that is all of it you need — and the four
at the top are the ones that matter on a machine somebody is waiting for.
