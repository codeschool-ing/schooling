---
title: Temporary files, and cleaning up when you did not plan to stop
version: 1
---

A script that needs scratch space has two problems: picking a name nobody else will pick, and
deleting it however the script ends.

## `mktemp`

```
ana@vm:~/work/scripts$ mktemp -d /tmp/work.XXXXXX
/tmp/work.YPo5kn
```

**`mktemp` creates the file or directory and prints its name**, atomically. The `XXXXXX` is
replaced with random characters; `-d` makes a directory instead of a file.

Not `/tmp/myscript.tmp`, and not `/tmp/myscript.$$` either. `$$` is the process id, which is
predictable and reused, and a fixed name is worse: two copies of the script running at once
overwrite each other's work, and anyone on the machine can create `/tmp/myscript.tmp` as a symlink
pointing somewhere interesting before you do.

`mktemp` creates it owned by you and readable by nobody else, in one operation that cannot be
raced:

```
ana@vm:~/work/scripts$ f=$(mktemp); d=$(mktemp -d); ls -ld "$f" "$d"; rm -rf "$f" "$d"
drwx------ 2 ana ana 4096 Sep 15 10:22 /tmp/tmp.7WT247IVW4
-rw------- 1 ana ana    0 Sep 15 10:22 /tmp/tmp.GCpTPnFgyN
```

`700` and `600` — section 57's octal. With no template at all it picks the name and the directory
itself, which is the spelling to use when you do not care where it lands.

**A temporary directory is usually better than a temporary file**, because a script that needs one
scratch file usually ends up needing three, and one `rm -rf` cleans up all of them.

## The cleanup that does not happen

```
ana@vm:~/work/scripts$ cat leaky.sh; ./leaky.sh; ls /tmp/leaky.* 2>&1
#!/bin/bash
tmp=$(mktemp /tmp/leaky.XXXXXX)
echo "working in $tmp"
echo data > "$tmp"
exit 1
working in /tmp/leaky.qpK48w
/tmp/leaky.qpK48w
```

The script exited on an error path and left the file behind. Run it on a schedule and `/tmp` fills
up over months — slowly enough that nobody connects the full disk to the script.

**An `rm` at the bottom of the file does not fix this**, because the bottom of the file is exactly
where a failing script does not reach.

## `trap`

```
ana@vm:~/work/scripts$ cat tidy.sh; ./tidy.sh; ls /tmp/tidy.* 2>&1
#!/bin/bash
tmp=$(mktemp /tmp/tidy.XXXXXX)
trap 'rm -f "$tmp"' EXIT
echo "working in $tmp"
echo data > "$tmp"
exit 1
working in /tmp/tidy.58ZF4t
ls: cannot access '/tmp/tidy.*': No such file or directory
```

**`trap 'command' EXIT` runs that command whenever the shell exits** — normally, from an `exit`
anywhere in the file, or because `set -e` stopped it.

The placement is the part to get right: **immediately after the `mktemp`, on the next line.** Not
at the end of the script, not after the validation. Everything between creating the thing and
setting the trap is a window in which the script can die and leave it behind.

```sh
work=$(mktemp -d /tmp/logreport.XXXXXX)
trap 'rm -rf "$work"' EXIT
```

Note the single quotes: the command is stored and evaluated **when the trap fires**, so `$work` is
expanded then. With double quotes it would be expanded now, which happens to work here and does not
when the variable is set later.

## Signals

```
ana@vm:~/work/scripts$ cat trapped.sh
#!/bin/bash
cleanup() { echo "cleanup ran, signal or not"; }
trap cleanup EXIT
trap 'echo "caught an interrupt"; exit 130' INT
echo "my pid is $$"
sleep 30
echo "not reached"
ana@vm:~/work/scripts$ ./trapped.sh
my pid is 9852
^Ccaught an interrupt
cleanup ran, signal or not
ana@vm:~/work/scripts$ echo "exit status $?"
exit status 130
```

That `^C` is a real Ctrl-C. The `INT` handler ran, exited with 130, and **the `EXIT` handler ran
too** — because `exit` is still an exit.

This is the arrangement to copy: put the cleanup on `EXIT` and let signal handlers do their own
thing and then exit. One cleanup, one place, reached however the script ends.

| | |
|---|---|
| `EXIT` | any exit. **The one you want for cleanup** |
| `INT` | Ctrl-C |
| `TERM` | `kill`, and what a service manager sends on stop |
| `HUP` | the terminal went away (section 96) |
| `ERR` | bash's own: any command that would trip `set -e` |

Section 93's rule still holds: **`KILL` cannot be trapped.** `kill -9` gives your script no chance
to clean up, which is one more reason to prefer plain `kill`.

And 130 as an exit status is not arbitrary: it is 128 plus signal 2, the convention from section 99.

## `trap … ERR` for a message

```
ana@vm:~/work/scripts$ cat errtrap.sh
#!/bin/bash
set -e
trap 'echo "failed at line $LINENO" >&2' ERR
echo "step one"
cp /etc/nosuchfile /tmp/x 2>/dev/null
echo "never reached"
ana@vm:~/work/scripts$ ./errtrap.sh; echo "exit $?"
step one
failed at line 5
exit 1
```

The `cp`'s own message was thrown away by the `2>/dev/null`, and the script would otherwise have
stopped in silence — which is what `set -e` does on its own. Three words and a line number instead.

It is not perfect: `$LINENO` inside a function reports the line within the function. But "failed at
line 5" is a great deal more than nothing, and it costs one line at the top of the file.

## Two more habits

**Everything through one variable.** `work=$(mktemp -d …)` once, and then `"$work/status"`,
`"$work/slow"`. One trap cleans up all of it, and nothing in the script names `/tmp` again.

**`TMPDIR` is respected by `mktemp` when you do not give it a template:**

```
ana@vm:~/work/scripts$ TMPDIR=/home/ana/work mktemp
/home/ana/work/tmp.oyq8gILcPd
```

So `t=$(mktemp)` puts the file wherever the environment says, which matters on systems where `/tmp`
is small, or where a service manager has given each unit a private one. A hard-coded `/tmp/…`
template opts out of that.
