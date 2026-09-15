---
title: Exit statuses, and what `$?` is really telling you
version: 1
---

Section 88 said a process ends by handing a number to its parent. This is that number, and it is
the only thing a program can say about how it went that another program can act on.

**Zero is success. Everything else is a failure.** That is backwards from most things and it is the
right way round here, because there is one way to succeed and many ways to fail — so the failures
get the numbers.

`$?` is the status of the last command:

```
ana@vm:~/work$ true; echo $?
0
ana@vm:~/work$ false; echo $?
1
```

`true` and `false` are real programs that do nothing except exit with 0 and 1. They exist so that
scripts have something to say "yes" and "no" with.

## The numbers you will meet

```
ana@vm:~/work$ ls /nosuchplace; echo $?
ls: cannot access '/nosuchplace': No such file or directory
2
ana@vm:~/work$ grep nosuchpattern README.md; echo $?
1
ana@vm:~/work$ nosuchcommand; echo $?
bash: nosuchcommand: command not found
127
ana@vm:~/work$ /etc/hostname; echo $?
bash: /etc/hostname: Permission denied
126
ana@vm:~/work$ bash -c "exit 42"; echo $?
42
```

| | |
|---|---|
| `0` | success |
| `1` | the general failure, and **`grep`'s "found nothing"** |
| `2` | by convention, the arguments were wrong — `ls` uses it for a missing path |
| `126` | found it, **could not run it** — the permission from lesson 4 |
| `127` | **command not found** |
| `128+n` | killed by signal `n` |
| any | whatever the program chose. `exit 42` means 42 |

**`126` and `127` are the two worth memorising**, because they are the two you get from a script
rather than from the thing the script was trying to do. `127` in a log is a typo or a missing
package; `126` is a file without its execute bit, which lesson 4 section 62 was about.

**And `grep`'s `1` is not an error.** It means the pattern was not there, which is frequently the
answer you wanted. Section 90's `pgrep` uses the same convention for the same reason.

## Signals, in the status

```
ana@vm:~/work$ sh -c "kill -TERM \$\$"; echo $?
Terminated
143
ana@vm:~/work$ sleep 60
^C

ana@vm:~/work$ 
ana@vm:~/work$ echo $?
130
```

**128 plus the signal number.** `TERM` is 15, so 143. `INT` is 2, so 130 — which is what you get
every time you press `Ctrl+C`, and is why 130 turns up in logs so often. Section 93's `SIGPIPE` was
141 for the same arithmetic.

So a status above 128 is worth reading as a subtraction: **`137` is `128 + 9`, which is `SIGKILL`,
which is very often the out-of-memory killer** rather than a person. That single fact has explained
more mysterious container restarts than any other number in this lesson.

## Where it goes wrong: pipelines

```
ana@vm:~/work$ false | true; echo $?
0
```

**`false` failed and the status is `0`.** `$?` after a pipeline is the status of the **last**
command, and the last command succeeded. Every step before it can fail silently.

That is why `curl badurl | tar xz` has ruined afternoons: `curl` fails, prints nothing useful, and
`tar` reports whatever it thinks of the empty input.

Two ways out, and bash has both:

```
ana@vm:~/work$ false | true; echo "${PIPESTATUS[@]}"
1 0
ana@vm:~/work$ set -o pipefail
ana@vm:~/work$ false | true; echo $?
1
```

`PIPESTATUS` is an array with **one status per stage**, and it is the only way to find out which
stage failed. Section 93 used it to catch `yes` being killed by `SIGPIPE`.

**`set -o pipefail` changes the rule**: the pipeline's status becomes the last non-zero one. In a
script that does anything with pipes, this line belongs at the top and the day you need it is the
day you find out it was not there.

## Using it: `&&` and `||`

```
ana@vm:~/work$ mkdir -p build && echo made it
made it
ana@vm:~/work$ ls /nosuchplace || echo "fell back"
ls: cannot access '/nosuchplace': No such file or directory
fell back
ana@vm:~/work$ test -f README.md && echo present
present
```

`&&` runs the next thing **only if the previous one succeeded**; `||` only if it failed. They are
`$?` used without being written down, and they are how most shell logic is actually spelled.

`test` — also spelled `[ ]` — exists purely to produce a status: `test -f file` is 0 if the file
exists and 1 if it does not, and prints nothing either way. **That is the whole design.** Lesson 9
is where this becomes `if`.

## In scripts

| | |
|---|---|
| `exit 0` | say it worked |
| `exit 1` | say it did not |
| `set -e` | stop the script at the first command that fails |
| `set -o pipefail` | count failures inside pipelines |
| `set -u` | fail on an unset variable, which is a different bug and the same discipline |

`set -euo pipefail` is the line at the top of a well-behaved bash script, and now every piece of it
has a reason rather than being copied. Lesson 9 takes it apart properly, including the places
`set -e` does not do what it looks like it does.

**And give your own scripts real statuses.** A script that always exits 0 cannot be used by anything
— not by `&&`, not by a cron job's failure mail, not by lesson 5's `Restart=on-failure`, which reads
exactly this number to decide whether a service died or finished. The number is the whole interface
between your program and everything that runs it.
