---
title: Reading a refusal
version: 2
---

A terminal tells you more when it refuses than any interface you have used tells you when it
succeeds. The information is all there; it is just terse, and nobody teaches the grammar.

**Every error you will meet has three parts:** who is speaking, what they were working on, and
what went wrong.

```localised
cat: /etc/shadow: Permission denied
└┬┘  └────┬────┘  └───────┬──────┘
 │        │               └─ what went wrong
 │        └───────────────── what it was working on
 └────────────────────────── who is speaking
```

Read it left to right and the error names its own cause. `cat` is speaking, so `cat` ran — the
command was found and started. It was working on `/etc/shadow`, so the argument reached it. And it
was refused, which section 03 already told you is the kernel's answer, not the program's opinion.

## The four you will meet this week

**Command not found.**

```
ana@vm:~$ celar
bash: celar: command not found
```

`bash:` is the speaker — the shell, not a program, because no program was reached. It searched and
found nothing by that name. A typo, or something that is not installed.

**Permission denied.**

```
ana@vm:~$ cat /etc/shadow
cat: /etc/shadow: Permission denied
```

The program ran and the kernel said no. Section 14 shows why for this file. Not a bug, and not
usually something to fix with `sudo` before you have understood what you are asking for.

**No such file or directory.**

```
ana@vm:~$ ls /nowhere
ls: cannot access '/nowhere': No such file or directory
```

The program ran, took its argument, and the path does not exist. Nine times in ten it is a typo or
the wrong directory — and `pwd` and Tab, from sections 06 and 08, are the two things that would
have prevented it.

**Invalid option.**

```
ana@vm:~$ ls -Z9
ls: invalid option -- '9'
Try 'ls --help' for more information.
```

The program ran and refused a flag. Notice it names the character, not the whole word, and
notice it tells you where to look next — which is section 16's `--help`, offered by the program
itself.

## The number nobody shows you

Every command leaves behind a number saying how it went, and the shell keeps the last one in `$?`:

```
ana@vm:~$ true
ana@vm:~$ echo $?
0
```

**Zero means it worked.** Anything else means it did not, and that convention is the whole reason
lesson 9 can write `command && next_command`.

Watch the four failures above answer differently:

| command | `$?` | |
|---|---|---|
| `true` | `0` | it worked |
| `cat /etc/shadow` | `1` | a general failure |
| `ls /nowhere` | `2` | `ls` uses 2 for "serious trouble" |
| `ls -Z9` | `2` | same program, same kind of complaint |
| `celar` | `127` | **the shell's**: no such command |
| `Ctrl+C` on anything | `130` | interrupted — section 08 |

Two of those are worth memorising because they are the shell's own: **127 is "I could not find
it"** and **130 is "you pressed Ctrl+C"**. The rest are each program's business, and `man` says
what they mean.

## The habit

When something fails, in this order:

1. **Read the first word.** It names who is complaining, and that alone narrows it to a layer.
2. **Read the last part.** It says what went wrong in English.
3. **`pwd` and `ls`.** More failures are "wrong directory" than are anything else.
4. **`type` it** — section 16 — if the command itself is behaving unexpectedly.
5. **`echo $?`** when a command failed silently, which happens.

**And do not reach for `sudo` first.** `Permission denied` is the system telling you that what you
asked for is not yours to do. Sometimes the answer is to ask as root; often the answer is that you
are in the wrong directory, or editing the wrong copy, and `sudo` would have made a mess with
authority.
