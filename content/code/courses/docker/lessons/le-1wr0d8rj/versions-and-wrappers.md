---
title: The right version, every time
version: 1
---

**The version of a tool is part of the image's tag, so running two versions side by side is
choosing two tags.** That is worth more than it sounds: "it works with my Python" stops being a
conversation when the version is written in the command.

## Two Pythons, one script

Ana's colleague wrote a short script that uses `copy.replace`, a function added to the standard
library in Python 3.13:

```python
import copy
from dataclasses import dataclass

@dataclass(frozen=True)
class Loan:
    book: str
    days: int

first = Loan("Dom Casmurro", 14)
renewed = copy.replace(first, days=28)
print(renewed)
```

Ana runs it under 3.13 and under 3.12, without either installed for the purpose:

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work python:3.13-slim python stats.py
Loan(book='Dom Casmurro', days=28)
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work python:3.12-slim python stats.py
Traceback (most recent call last):
  File "/work/stats.py", line 10, in <module>
    renewed = copy.replace(first, days=28)
              ^^^^^^^^^^^^
AttributeError: module 'copy' has no attribute 'replace'
```

**The same file, two answers**, and the second one is the bug report somebody running 3.12 on
their own machine would have sent. The tag `python:3.12-slim` is the whole of the environment:
nobody has to ask which Python the other person has.

## Files the tool writes belong to the container's user

Lesson 8 showed it for a long-running container, and it applies even more to tools, because tools
are run all day in your own directories:

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work python:3.13-slim python -c "open('out.txt', 'w').write('x')"
ana@vm:~/ops$ ls -l out.txt
-rw-r--r-- 1 root root 1 Oct  6 13:52 out.txt
ana@vm:~/ops$ rm -f out.txt
ana@vm:~/ops$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/work -w /work python:3.13-slim python -c "open('out.txt', 'w').write('x')"
ana@vm:~/ops$ ls -l out.txt
-rw-r--r-- 1 ana ana 1 Oct  6 13:52 out.txt
```

The first file belongs to `root`, because the `python` image runs as root. With `--user` set to
Ana's own user and group numbers, the second belongs to her. **Any tool that writes into your
directory should get `--user "$(id -u):$(id -g)"`**; tools that only read, like the linters above,
do not need it.

## Making it feel installed

Typing the whole `docker run` every time gets old quickly. A shell function with the tool's name
hides it, and Ana keeps hers in a file:

```schooling-example
{"language": "sh", "file": "tools.sh", "parts": [{"code": "# Tools that run in containers. Source this file from ~/.bashrc to keep them.\n", "note": "A comment for whoever opens the file later: what it is for, and how it gets loaded."}, {"code": "yq() {\n  docker run --rm -i \\\n", "note": "A shell function named after the tool, so typing `yq` runs it. `--rm` cleans up, `-i` keeps standard input open so a file can be piped in."}, {"code": "    -v \"$PWD\":/work -w /work \\\n", "note": "The current directory, mounted and made the working directory, so relative paths behave as they do on the host."}, {"code": "    --user \"$(id -u):$(id -g)\" \\\n", "note": "The container runs as Ana's own user and group, so any file `yq` writes belongs to her."}, {"code": "    mikefarah/yq:4 \"$@\"\n}\n\n", "note": "The image, with its major version pinned, and `\"$@\"`: every argument Ana typed, passed on exactly as typed."}, {"code": "shellcheck() {\n  docker run --rm -v \"$PWD\":/mnt -w /mnt \\\n    koalaman/shellcheck:stable \"$@\"\n}\n", "note": "The same pattern for ShellCheck. It only reads files, so it needs no `--user` and no `-i`."}]}
```

```
ana@vm:~/ops$ . ./tools.sh
ana@vm:~/ops$ yq ".database.pool" config.yaml
10
ana@vm:~/ops$ shellcheck --severity=warning backup.sh; echo "exit status $?"
exit status 0
```

After sourcing the file, `yq` and `shellcheck` are functions, and they behave like installed
commands on files in the current directory. `--severity=warning` hides ShellCheck's `info` level,
which is where SC2086 sat, so this time it reports nothing and exits 0. Putting `. ~/ops/tools.sh`
in `~/.bashrc` keeps the functions in every new shell.

Two details make the functions trustworthy. **The tag is written out**, `yq:4` and `shellcheck:stable`,
so the tool does not change version silently; for a tool whose output a pipeline depends on, pin the
exact version, as lesson 16 recommends. And **`"$@"` passes every argument through untouched**,
quotes and spaces included, which is the difference between a wrapper and a source of strange bugs.
