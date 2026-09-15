---
title: `grep`, and the six flags that cover almost everything
version: 1
---

`grep` prints the lines that match. That is all it does, and it is the command you will type more
than any other in this lesson.

```
ana@vm:~/work$ grep -c " 500 " logs/access.log
21
ana@vm:~/work$ grep -n "/admin" logs/access.log | head -3
165:10.0.1.33 - - [14/Sep/2026:07:59:27 +0000] "GET /admin HTTP/1.1" 403 16628 "kube-probe/1.29" 115
433:10.0.1.24 - - [14/Sep/2026:11:20:59 +0000] "GET /admin HTTP/1.1" 403 21827 "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" 98
449:203.0.113.5 - - [14/Sep/2026:11:31:01 +0000] "GET /admin HTTP/1.1" 403 20646 "python-requests/2.32.3" 46
```

## The six

| | |
|---|---|
| `-i` | ignore case |
| `-v` | **invert**: print the lines that do *not* match |
| `-c` | count matching **lines** |
| `-n` | prefix each with its line number |
| `-r` | recurse into directories |
| `-l` | print only the **names** of files that matched |

```
ana@vm:~/work$ grep -c -v " 200 " logs/access.log
167
ana@vm:~/work$ grep -i "GOOGLEBOT" logs/access.log | wc -l
159
ana@vm:~/work$ grep -l "admin" logs/*.log
logs/access.log
ana@vm:~/work$ grep -r "app started" logs/ | head -3
logs/app.log:app started
logs/app.log:app started
logs/app.log:app started
```

**`-v` is the one that does the most work in practice.** Most investigations are "everything except
the noise", and `grep -v` chained two or three times is how that gets written.

**`-l` is for finding which file**, not what is in it. `grep -rl TODO src/` gives you a list of
filenames you can pass to something else — which is section 134's `xargs`.

And note that `grep -r logs/` printed `logs/app.log:` in front of each line. **`grep` prefixes the
filename whenever it is searching more than one file**, which is helpful on screen and a nuisance in
a pipeline. `-h` turns it off; `-H` forces it on even for one file.

## `-c` counts lines, not matches

```
ana@vm:~/work$ grep -c o <<< "hello world"
1
```

One line, two `o`s, and the answer is 1. **`grep -c` is a line count**, always.

To count occurrences you need `-o`, which prints each match on its own line:

```
ana@vm:~/work$ grep -o "GET\|POST\|PUT\|DELETE" logs/access.log | sort | uniq -c
     28 DELETE
    975 GET
    167 POST
     30 PUT
```

**`-o` is how `grep` becomes an extractor** rather than a filter. Combined with `sort | uniq -c` it
answers "how often does each of these appear", which is a question people reach for a script to
answer.

## Context

```
ana@vm:~/work$ grep -A1 -B1 " 500 " logs/access.log | head -6
10.0.1.33 - - [14/Sep/2026:06:08:07 +0000] "GET /health HTTP/1.1" 200 3411 "kube-probe/1.29" 42
10.0.1.21 - - [14/Sep/2026:06:09:02 +0000] "POST /api/reports HTTP/1.1" 500 18487 "curl/8.5.0" 5833
10.0.1.36 - - [14/Sep/2026:06:09:03 +0000] "GET / HTTP/1.1" 200 20657 "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36" 79
--
198.51.100.9 - - [14/Sep/2026:06:45:22 +0000] "GET / HTTP/1.1" 200 7628 "kube-probe/1.29" 52
198.51.100.17 - - [14/Sep/2026:06:45:55 +0000] "GET /favicon.ico HTTP/1.1" 500 5887 "kube-probe/1.29" 129
```

`-A` after, `-B` before, `-C` both. The `--` is `grep` separating non-adjacent groups.

**This is the flag for reading a stack trace.** The line with `Exception` on it is rarely the useful
one; `grep -A20 Exception app.log` is.

## The exit status is the point

```
ana@vm:~/work$ grep -q " 500 " logs/access.log; echo "found 500s: $?"
found 500s: 0
ana@vm:~/work$ grep -q " 418 " logs/access.log; echo "found 418s: $?"
found 418s: 1
```

`-q` prints nothing and exits 0 or 1. **That makes `grep` a question rather than a source of text**,
and it is how a script asks "is this in the file":

```
if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then ...
```

Section 99's warning applies here: under `set -e`, a `grep` that finds nothing stops the script,
because "no match" is a non-zero status. In an `if`, or with `|| true`, it is fine.

## Which grep are you running

There are three pattern languages and the flag picks one:

| | |
|---|---|
| `grep` | basic regular expressions — `+`, `?`, `\|`, `()` need backslashes |
| `grep -E` | **extended** — those characters work as themselves. Same as `egrep` |
| `grep -F` | **fixed strings** — no pattern language at all. Same as `fgrep` |

```
ana@vm:~/work$ grep -E "^10\.0\.1\.[0-9]+ " logs/access.log | wc -l
651
ana@vm:~/work$ grep -F "." logs/access.log | wc -l
1200
```

The second one is the demonstration: **`-F` made the dot an ordinary dot**, so it matched every line
that contains a full stop, which is all of them. Without `-F`, `.` is "any character" and would also
have matched all of them — the same answer for a different reason, which is exactly why this is
worth being deliberate about.

**Use `-E` by default.** The basic syntax is a historical accident, and writing `\(` and `\|` is a
tax with no benefit. **Use `-F` when the pattern is user input or contains dots, brackets or
slashes** — searching for an IP address, a version number or a path is the common case, and `-F` is
both correct and faster.

Section 125 is the pattern language itself.

## Two more worth knowing

**`grep -w`** matches whole words, so `grep -w cat` does not match `category`. It is the flag people
reinvent with `\b` and it is shorter.

**`grep --include`** narrows a recursive search by filename: `grep -r --include='*.py' TODO .`
searches only python files. On a large tree that is the difference between a search and a coffee
break.

And `ripgrep` — `rg` — is the modern replacement: same idea, much faster, respects `.gitignore`, and
searches recursively by default. It is not installed everywhere, which is why this section is about
`grep`. Where you have it, use it.
