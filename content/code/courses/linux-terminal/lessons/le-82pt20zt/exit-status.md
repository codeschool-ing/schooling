---
title: Strict mode, and the four places it does not help
version: 1
---

Section 99 established what an exit status is: zero for success, anything else for failure, in
`$?`. A script has one too, and it is whatever you gave `exit`:

```
ana@vm:~/work/scripts$ cat status.sh; ./status.sh; echo "exit status was $?"
#!/bin/bash
echo "starting"
exit 3
starting
exit status was 3
```

**A script with no `exit` ends with the status of its last command**, which is nearly always
`echo`, which nearly always succeeds. That is how a script that failed reports success.

## By default, nothing stops

```
ana@vm:~/work/scripts$ cat noset.sh withset.sh
#!/bin/bash
cp /etc/nosuchfile /tmp/dest.txt
echo "still running, and about to do damage"
#!/bin/bash
set -e
cp /etc/nosuchfile /tmp/dest.txt
echo "still running, and about to do damage"
ana@vm:~/work/scripts$ ./noset.sh; echo "noset.sh finished with $?"
cp: cannot stat '/etc/nosuchfile': No such file or directory
still running, and about to do damage
noset.sh finished with 0
```

Two files, printed one after the other, differing by one line.

The `cp` failed, said so, and **the next line ran anyway**. The script then exited zero, so
anything checking it was told everything went fine.

This is the default because the shell is a command interpreter first: at a prompt, one failed
command should not log you out. In a file it is exactly wrong.

```
ana@vm:~/work/scripts$ ./withset.sh; echo "withset.sh finished with $?"
cp: cannot stat '/etc/nosuchfile': No such file or directory
withset.sh finished with 1
```

The `cp` failed, the script stopped there, and the status it returned was the `cp`'s. One line of
difference between the two files, and one of them lies about what happened.

## The three settings

```sh
#!/usr/bin/env bash
set -euo pipefail
```

| | |
|---|---|
| `-e` | `errexit` — stop at the first command that fails |
| `-u` | `nounset` — expanding an unset variable is an error, not an empty string |
| `-o pipefail` | a pipeline fails if **any** stage failed, not just the last |

### `-u`, which is the one that saves a directory

```
ana@vm:~/work/scripts$ cat nounset.sh
#!/bin/bash
TARGET=/tmp/scratch-dir
echo "would remove $TARGE/old"
echo "reached the end"
ana@vm:~/work/scripts$ ./nounset.sh
would remove /old
reached the end
```

`TARGET` on one line, `$TARGE` on the next — one missing character. Without `-u`, `$TARGE` is
empty and the path is `/old`. Read that line as an `rm -rf` and you have the whole problem: **it
did not fail, it operated on the wrong thing**.

```
ana@vm:~/work/scripts$ cat unset.sh
#!/bin/bash
set -u
TARGET=/tmp/scratch-dir
echo "would remove $TARGET/old"
echo "would remove $TARGE/old"
echo "reached the end"
ana@vm:~/work/scripts$ ./unset.sh; echo "script exit: $?"
would remove /tmp/scratch-dir/old
./unset.sh: line 5: TARGE: unbound variable
script exit: 1
```

Same typo, `set -u` on. The correct line ran; the typo was named, with the line number, and the
script stopped.

### `pipefail`, which is the one people have never heard of

```
ana@vm:~/work/scripts$ cat pipe.sh; ./pipe.sh; echo "script exit: $?"
#!/bin/bash
set -e
grep nothing /etc/hostname | wc -l
echo "reached the end anyway, status of the pipeline was $?"
0
reached the end anyway, status of the pipeline was 0
script exit: 0
```

`grep` found nothing, so it exited 1. `wc -l` counted the nothing it was given and exited 0.
**A pipeline's status is its last command's**, so the pipeline succeeded, `set -e` saw no failure,
and the script carried on.

```
ana@vm:~/work/scripts$ ./pipefail.sh; echo "script exit: $?"
0
script exit: 1
```

Adding `-o pipefail` to the same file: the `0` from `wc` is still printed — it really did run — and
then the script stops, because a stage of the pipeline failed.

If you want the detail rather than the verdict:

```
ana@vm:~/work/scripts$ grep nothing /etc/hostname | wc -l; echo "PIPESTATUS: ${PIPESTATUS[@]}"
0
PIPESTATUS: 1 0
```

**`PIPESTATUS` is an array with one status per stage**, left to right, and it is only valid
immediately after the pipeline.

## The four places `set -e` does nothing

This matters more than the setting itself, because a script with `set -e` at the top *looks* safe.

```
ana@vm:~/work/scripts$ cat seholes.sh
#!/bin/bash
set -e
if false; then echo "no"; fi
echo "1: a false condition did not stop the script"
false || echo "2: the left of || may fail"
false && echo "never"
echo "3: even a bare false-and-something did not stop it"
check() { false; echo "4: and inside a function used as a condition, it goes on"; }
if check; then :; fi
false
echo "5: this line is never reached"
ana@vm:~/work/scripts$ ./seholes.sh; echo "exit: $?"
1: a false condition did not stop the script
2: the left of || may fail
3: even a bare false-and-something did not stop it
4: and inside a function used as a condition, it goes on
exit: 1
```

Four failing commands ran and the script continued past all of them. The fifth one stopped it, and
line 5 never printed.

| | |
|---|---|
| in an `if`/`while` condition | the whole point of a condition is that it may be false |
| left of `&&` or `\|\|` | you are already handling the failure yourself |
| the `false &&` case | the *last* command of the list decides, and it did not run |
| **anywhere inside a function called as a condition** | `-e` is suspended for the entire call |

The last one is the nasty one. `check` failed on its first line and kept going, because the whole
function was being used as a condition. **`set -e` does not nest into a call whose result you are
testing**, which means a validation function can be quietly running past its own failures.

## So what do you actually do

Put `set -euo pipefail` at the top of every script. It is not a safety net — the holes above are
real — but every one of them is a place where it *does not help*, not a place where it hurts.

And then check the things that matter explicitly, because that is what the holes tell you:

```
ana@vm:~/work/scripts$ cat handled.sh
#!/bin/bash
set -euo pipefail
if ! cp /etc/nosuchfile /tmp/dest.txt 2>/dev/null; then
  echo "could not copy the file, carrying on without it" >&2
fi
grep -q nothing /etc/hostname || true
echo "reached the end"
ana@vm:~/work/scripts$ ./handled.sh; echo "exit $?"
could not copy the file, carrying on without it
reached the end
exit 0
```

Two failures under `set -e`, neither of which stopped anything, and both of them deliberate. The
`if !` handles one; the `|| true` waves the other through.

**`|| true` is the honest spelling of "I know this can fail and I do not care".** A reader who sees
it knows it was a decision. A reader who sees a bare command under `set -e` cannot tell whether the
failure was considered.
