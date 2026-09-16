---
title: A script is the commands you already type, in a file
version: 1
---

There is no new language in this lesson. **A bash script is a file containing the commands you
would have typed**, and the first one is one line long.

```
ana@vm:~/work/scripts$ printf '%s\n' 'echo "hello from a file"' > greeting.sh
ana@vm:~/work/scripts$ cat greeting.sh
echo "hello from a file"
ana@vm:~/work/scripts$ ls -l greeting.sh
-rw-r--r-- 1 ana ana 25 Sep 15 09:58 greeting.sh
ana@vm:~/work/scripts$ greeting.sh
bash: greeting.sh: command not found
ana@vm:~/work/scripts$ ./greeting.sh
bash: ./greeting.sh: Permission denied
ana@vm:~/work/scripts$ bash greeting.sh
hello from a file
ana@vm:~/work/scripts$ chmod +x greeting.sh
ana@vm:~/work/scripts$ ./greeting.sh
hello from a file
```

Four attempts, three different outcomes, and each one is a rule.

| | |
|---|---|
| `greeting.sh` | **command not found** — the shell searches `$PATH`, and `.` is not on it |
| `./greeting.sh` | **permission denied** — the file is readable but not executable |
| `bash greeting.sh` | works — you are running `bash` and handing it a file to read |
| `chmod +x`, then `./` | works — now the kernel will execute the file itself |

**The `./` is not decoration.** It is a path, and it is required because the current directory is
deliberately absent from `$PATH` — if it were present, a file called `ls` dropped in a directory
you happened to `cd` into would run instead of the real one. Lesson 3 section 04 covered that; this
is where you feel it.

## The shebang

`bash greeting.sh` worked without one, because you named the interpreter yourself. `./greeting.sh`
needs the file to name it, and that is the first line:

```
#!/bin/bash
```

The `#!` is read by the kernel, not by bash. It says: *run this program, and give it this file as
an argument.* Which is why it must be the **first two bytes of the file** — not after a comment,
not after a blank line.

Get it wrong and the error names the wrong thing:

```
ana@vm:~/work/scripts$ cat badshebang.sh
#!/usr/bin/bsh
echo never
ana@vm:~/work/scripts$ ./badshebang.sh
bash: ./badshebang.sh: cannot execute: required file not found
```

**The "required file" is `/usr/bin/bsh`, not `badshebang.sh`.** The script is right there and
readable; it is the interpreter that is missing. This message has cost people an hour more than
once, and now it will not cost you one.

## `/bin/sh` is not bash

```
ana@vm:~/work/scripts$ ls -l /bin/sh
lrwxrwxrwx 1 root root 4 Mar 31  2024 /bin/sh -> dash
ana@vm:~/work/scripts$ cat which.sh
echo "the shell running me is $0"
x=hello
if [[ $x == h* ]]; then echo "double brackets work"; fi
ana@vm:~/work/scripts$ bash which.sh
the shell running me is which.sh
double brackets work
ana@vm:~/work/scripts$ sh which.sh
the shell running me is which.sh
which.sh: 3: [[: not found
```

**On Debian and Ubuntu, `/bin/sh` is `dash`** — a smaller, faster, strictly POSIX shell, chosen
because the system's own boot scripts run under it thousands of times. It does not have `[[ ]]`,
it does not have arrays, and it does not have `$(( ))`'s full arithmetic.

So a script with `#!/bin/sh` that uses bash syntax fails, and fails *in the middle*:

```
ana@vm:~/work/scripts$ cat shebang.sh
#!/bin/sh
echo "argv zero is $0"
[[ x == x ]] && echo "bash-only syntax ran"
ana@vm:~/work/scripts$ ./shebang.sh
argv zero is ./shebang.sh
./shebang.sh: 3: [[: not found
```

Line 2 ran. Line 3 did not. **A script that half-ran is worse than one that did not start**, and
this is the single most common way to produce one.

The rule is short: **if you are writing bash, say bash.** `#!/bin/sh` is a promise that the file
contains nothing but POSIX, and it is a promise most people break by accident.

## `#!/bin/bash` or `#!/usr/bin/env bash`

```
ana@vm:~/work/scripts$ type -a bash; command -v env
bash is /usr/bin/bash
bash is /bin/bash
/usr/bin/env
```

| | |
|---|---|
| `#!/bin/bash` | exactly that file. Fine on Linux, wrong on macOS with a newer bash from Homebrew |
| `#!/usr/bin/env bash` | the first `bash` on `$PATH`, whichever that is |

**`env bash` is the portable one** and the one to default to. `/bin/bash` is the one to use when
you specifically want the system's bash and not a user's — an init script, something running as
root, anything where `$PATH` is not yours.

## Running versus sourcing

This is the distinction that catches everybody once.

```
ana@vm:~/work/scripts$ cat goto.sh
#!/bin/bash
cd /tmp
echo "inside the script, pwd is $PWD"
VISITED=yes
ana@vm:~/work/scripts$ ./goto.sh
inside the script, pwd is /tmp
ana@vm:~/work/scripts$ pwd
/home/ana/work/scripts
ana@vm:~/work/scripts$ echo "VISITED is [${VISITED:-unset}]"
VISITED is [unset]
ana@vm:~/work/scripts$ source goto.sh
inside the script, pwd is /tmp
ana@vm:/tmp$ pwd
/tmp
ana@vm:/tmp$ echo "VISITED is [${VISITED:-unset}]"
VISITED is [yes]
```

**`./goto.sh` started a new shell.** It changed directory, set a variable, and then exited — and
everything it changed died with it. Look at the prompt: it never moved.

**`source goto.sh` ran the same lines in the shell you are sitting in.** The prompt changed to
`/tmp`, and `VISITED` is still set afterwards.

| | |
|---|---|
| `./script.sh` | a child process. Cannot change your directory, your variables or your shell |
| `bash script.sh` | the same thing, spelled differently |
| `source script.sh` | your own shell runs the lines. Everything it does, sticks |
| `. script.sh` | `source`, spelled the POSIX way |

**A script cannot change the directory of the shell that ran it, and this is not a limitation to
work around — it is the reason scripts are safe to run.** When you want the effect to stick, the
tool is `source`, and that is why things like `activate` for a Python virtualenv tell you to source
them rather than run them.

## Where to put it

`./script.sh` from the directory it is in works. For something you will run often, put it on
`$PATH`:

```
mkdir -p ~/.local/bin
mv logreport.sh ~/.local/bin/logreport      # the .sh is only a habit, not a requirement
```

`~/.local/bin` is on `$PATH` on most modern distributions; `echo $PATH` tells you. **The `.sh`
extension means nothing to the kernel** — the shebang decides what runs it — and dropping it makes
your script look like every other command, which is the point.
