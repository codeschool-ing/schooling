---
title: Patterns, and who expands them
version: 2
---

**The single most important fact in this section:** the shell expands a pattern *before* the
command runs. The command never sees your `*`. It sees the list of filenames the shell handed it.

Prove it with `echo`, which only prints what it was given:

```
ana@vm:~/gl$ ls
a.txt  b.txt  c.log  sub
ana@vm:~/gl$ echo *
a.txt b.txt c.log sub
ana@vm:~/gl$ echo *.txt
a.txt b.txt
```

`echo` has no idea what a file is. It printed four words because **the shell replaced `*` with
four words** on its way to the command. This is called *globbing*, and it happens to every command
you type, always, whether that command knows about files or not.

## The four patterns

| | matches |
|---|---|
| `*` | any run of characters, including none |
| `?` | exactly one character |
| `[abc]` | one character from the set |
| `[a-z]`, `[0-9]` | one character from the range |
| `[!a]`, `[^a]` | one character that is **not** that |

```
ana@vm:~/gl$ echo [ab].txt
a.txt b.txt
ana@vm:~/gl$ echo [!a]*.txt
b.txt
ana@vm:~/gl$ echo ??.txt
??.txt
```

That last line is the behaviour to memorise, and the next section is about it.

## When nothing matches, the pattern is left alone

```
ana@vm:~/gl$ echo nope*
nope*
ana@vm:~/gl$ ls nope*
ls: cannot access 'nope*': No such file or directory
```

**If a glob matches nothing, bash passes it through literally.** So `ls` was genuinely handed a
filename containing a star, went looking for a file called `nope*`, and did not find one.

That is why the error message has a star in it — a detail that confuses people who assume `ls` did
the matching. It did not. It never does.

You can change the behaviour:

```
ana@vm:~/gl$ shopt -s nullglob
ana@vm:~/gl$ echo nope*
ana@vm:~/gl$ shopt -u nullglob
```

With `nullglob` on, an unmatched pattern becomes *nothing at all* rather than itself. That is
often what a script wants, and it is off by default because it would surprise everybody.

## Globs are not regular expressions

They look alike and they are not, and mixing them up is a rite of passage:

| | glob | regular expression |
|---|---|---|
| any run of characters | `*` | `.*` |
| one character | `?` | `.` |
| `*` on its own | everything | *zero or more of the previous thing* |
| used by | the shell, on filenames | `grep`, `sed`, editors, on text |

Lesson 8 teaches regular expressions properly. Until then the rule is: **a pattern typed at the
shell to match filenames is a glob.** A pattern given to `grep` is not.

## What `*` does *not* match

**It does not cross a `/`.** `*.txt` matches names in the current directory only; `*/*.txt`
matches one level down; and finding a pattern anywhere below you is `find`'s job (section 09) or
`**` with `shopt -s globstar`.

**It does not match a leading dot.** This is the reason `ls *` and `ls -a` disagree:

```
ana@vm:~/gl$ echo *
a.txt b.txt c.log sub
ana@vm:~/gl$ echo .*
.hidden.txt
```

A hidden file is *deliberately* excluded from `*`, which is what makes `rm *` in your home
directory survivable — your `.bashrc` is not in the list. Modern bash also leaves `.` and `..` out
of `.*`, which older versions did not, and which was the source of some memorably bad afternoons.

## Braces are a different thing that looks the same

```
ana@vm:~/gl$ echo {jan,feb}-report.csv
jan-report.csv feb-report.csv
ana@vm:~/gl$ echo {1..3}
1 2 3
ana@vm:~/gl$ echo a{b,c}d
abd acd
```

**Brace expansion does not look at the filesystem at all.** `{jan,feb}` produced two words whether
or not those files exist — it is pure text generation, and it happens *before* globbing.

That makes it the tool for **creating**:

```
mkdir -p project/{src,tests,docs}
cp config.yml{,.bak}
```

The second one is worth staring at: `config.yml{,.bak}` expands to `config.yml config.yml.bak`,
which is a copy-to-backup in eleven characters. It is the one brace trick everybody eventually
learns.

## Where the "shell expands it first" rule pays off

### `ls *` in a directory with a subdirectory

```
ana@vm:~/gl$ ls
a.txt  b.txt  c.log  sub
ana@vm:~/gl$ ls *
a.txt  b.txt  c.log

sub:
d.txt
```

Two listings from one command, and nothing is wrong. The shell replaced `*` with
`a.txt b.txt c.log sub`, so `ls` was handed four arguments — three files and a directory. Listing a
directory means listing what is inside it, so it did. **`ls *` is not `ls`.**

### Quoting hands the pattern to the program

Section 09 said to quote `find`'s pattern, and now the reason is visible:

```
find . -name '*.c'      # find matches — correct
find . -name *.c        # the shell matched, and find got a filename
```

The second form works by accident when exactly one `.c` file is in the current directory, and
breaks confusingly when there are two or none. Quote it and the question never arises.

### A file whose name contains a star

Rare, and instructive. `rm '*'` deletes a file literally called `*`. `rm *` deletes everything.
One character of quoting, two very different mornings.

### And the habit worth building today

**Before a destructive command with a glob in it, run the glob through `ls` or `echo` first.**

```
ana@vm:~/gl$ echo *.log
c.log
```

That is the exact list `rm *.log` would remove, printed harmlessly. It costs three seconds, and it
is the only reliable defence against a pattern that matched more than you meant — because by the
time `rm` runs, the star is long gone and nothing is left to warn you.
