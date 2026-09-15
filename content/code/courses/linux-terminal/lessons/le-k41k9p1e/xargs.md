---
title: `xargs`, for commands that take arguments instead of input
version: 1
---

Every tool so far reads stdin. A great many do not — `rm`, `cp`, `chmod`, `git`, `grep -l`'s output
fed to anything — and `xargs` is the adapter.

**It reads lines and turns them into arguments.**

```
ana@vm:~/work$ ls logs/*.log | xargs wc -l
  1200 logs/access.log
    30 logs/app.log
     0 logs/empty.log
     1 logs/error.log
  1231 total
```

Without `xargs`, `wc -l` would have read the *list of names* as its input and counted four lines.
With it, the names became arguments.

## It packs as many as it can

```
ana@vm:~/work$ printf "a\nb\nc\n" | xargs echo
a b c
ana@vm:~/work$ printf "a\nb\nc\n" | xargs -n1 echo saw
saw a
saw b
saw c
```

**By default `xargs` runs the command as few times as possible**, filling the command line up to the
system limit. That is what makes it fast: one `rm` with ten thousand arguments rather than ten
thousand `rm`s.

`-n1` forces one at a time, which you want when the command only takes one argument, or when you
need to see which one failed.

## `-I`, to put the argument somewhere other than the end

```
ana@vm:~/work$ printf "x\ny\n" | xargs -I{} echo "[{}]"
[x]
[y]
```

`-I{}` names a placeholder and puts the argument wherever it appears — which is how you write
`xargs -I{} mv {} {}.bak`, or anything where the argument is not last.

**`-I` implies `-n1`**, so it is one process per line. On ten thousand items that is slow, and it is
the trade for being able to place the argument.

## The failure, and the fix

```
ana@vm:~/work$ mkdir -p spaces && cd spaces && printf "one\n" > "a file.txt" && printf "two\n" > plain.txt && ls
'a file.txt'   plain.txt
ana@vm:~/work/spaces$ find . -type f | xargs wc -l
wc: ./a: No such file or directory
wc: file.txt: No such file or directory
1 ./plain.txt
1 total
ana@vm:~/work/spaces$ find . -type f -print0 | xargs -0 wc -l
1 ./a file.txt
1 ./plain.txt
2 total
```

**`xargs` splits on whitespace by default**, so `a file.txt` became two arguments and `wc` looked for
two files that do not exist.

The fix is a pair of flags that must be used together:

| | |
|---|---|
| `find -print0` | separate results with a **null byte** instead of a newline |
| `xargs -0` | expect null bytes |

A null byte cannot appear in a filename, which is why this is the only separator that is always
safe. **`find … -print0 | xargs -0 …` is the form to type by default**, not the one to remember when
a filename has a space in it — because the filename with a space in it will be somebody else's, on
a day you are not expecting it.

And notice how the failure behaved: it **half worked**. `plain.txt` was counted, the total said 1,
and a script checking only the exit status of the pipeline would have seen the failure — but a
script reading the total would have got a plausible wrong number.

## `find -exec`, which is the alternative

```
find . -name '*.log' -exec gzip {} \;      # one process per file
find . -name '*.log' -exec gzip {} +       # as many per process as fit
```

`-exec … \;` is `xargs -I{}`; `-exec … +` is plain `xargs`. **Neither needs `-print0`**, because
`find` hands the names to the command directly rather than through a stream.

So: **`-exec … +` when `find` is already in the pipeline**, and `xargs -0` when the list comes from
somewhere else.

## Two flags that save you

```
xargs -p          # prompt before each run
xargs -t          # print each command before running it
```

**`-t` is the one to use the first time you write anything with `xargs` and `rm` in it.** It prints
what it is about to do; combined with `echo` in front of the real command, it is a dry run:

```
find . -name '*.tmp' -print0 | xargs -0 echo rm      # shows what would go
find . -name '*.tmp' -print0 | xargs -0 rm           # does it
```

## `-r`, for the empty case

`xargs` with no input still runs the command once, with no arguments:

```
ana@vm:~/work$ printf "" | xargs echo "ran with:"
ran with:
ana@vm:~/work$ printf "" | xargs -r echo "ran with:"; echo "(nothing above means -r skipped it)"
(nothing above means -r skipped it)
ana@vm:~/work$ printf "" | xargs ls | head -3
Makefile
README.md
build
```

**The third one is the dangerous shape.** Nothing was found, `xargs` ran `ls` with no arguments, and
`ls` listed the current directory — so a pipeline that found nothing produced a full listing that
looks like a result. Substitute `rm` for `ls` and the consequence is obvious.

**`-r` — `--no-run-if-empty` — skips the command entirely when there is no input.** GNU `xargs` only;
on BSD it is the default. Put it in anything scripted.

## The whole thing in four lines

```
ls *.log | xargs wc -l                           # simple, no odd filenames
find . -name '*.log' -print0 | xargs -0 wc -l    # safe, always
find . -name '*.log' -exec gzip {} +             # find already has the names
printf '%s\n' a b | xargs -I{} mv {} {}.bak      # the argument is not last
```

**The second line is the one to make a habit**, because it is correct in every case and costs eight
characters.
