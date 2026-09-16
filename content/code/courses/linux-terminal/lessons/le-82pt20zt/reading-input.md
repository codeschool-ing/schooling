---
title: Reading lines, and the four things that go wrong
version: 1
---

The loop that reads a file line by line is one line long and has four traps in it. Here it is with
all four already avoided:

```
ana@vm:~/work/scripts$ cat readloop.sh
#!/bin/bash
n=0
while IFS= read -r line; do
  n=$((n+1))
  echo "$n: $line"
done < "$1"
echo "read $n lines"
ana@vm:~/work/scripts$ ./readloop.sh ~/work/logs/app.log | head -4
1: app started
2: app ready
3: app handled a request
4: app started
```

`read` takes one line from standard input, puts it in a variable, and exits non-zero at end of
file — which is what stops the `while`. The redirect is on the `done`, feeding the whole loop.

**`while IFS= read -r line` is one idiom, to be typed as one thing.** Here is what each piece buys.

## `-r`, for backslashes

```
ana@vm:/tmp/q2$ cat -A tricky.txt
C:\path\to\file$
   padded   $
ana@vm:/tmp/q2$ while read line; do echo "[$line]"; done < tricky.txt
[C:pathtofile]
[padded]
ana@vm:/tmp/q2$ while IFS= read -r line; do echo "[$line]"; done < tricky.txt
[C:\path\to\file]
[   padded   ]
```

**Without `-r`, `read` treats `\` as an escape character and eats it.** A Windows path lost all
three of its separators. So did anything else containing a backslash.

There is no case where you want that behaviour when reading data. `-r` always.

## `IFS=`, for whitespace

Look at the second line of the same output. `   padded   ` came back as `padded`.

**`read` splits on `$IFS` and strips leading and trailing whitespace** before assigning. Setting
`IFS=` empty for the duration of the `read` turns that off, and the line arrives as it is in the
file.

The `IFS=` goes *in front of `read`*, which is the one-command-one-variable form from section 03 —
it applies to that `read` and nothing else, so the rest of the script still has its normal `IFS`.

## `IFS=,`, when you want the splitting

The same mechanism, used deliberately, is how you read a delimited file:

```
ana@vm:~/work/scripts$ cat fields.sh
#!/bin/bash
while IFS=, read -r region rep quarter units revenue; do
  echo "$region/$rep sold $units for $revenue"
done < <(tail -n +2 "$1" | head -3)
ana@vm:~/work/scripts$ ./fields.sh ~/work/data/sales.csv
north/ana sold 171 for 8721
north/bruno sold 49 for 4116
south/carla sold 292 for 37084
```

**`read` with several variable names splits the line between them**, and the last one gets
everything that is left over — so `while read -r first rest` is "the first word and then the line".

This is a genuine alternative to `cut` and `awk` when you need the fields in a shell loop rather
than in a filter. It is also much slower — one `read` per line, in the shell — so for a big file,
lesson 8 section 14's `awk` is the answer.

Two limits worth knowing before you build a CSV parser with it: **this does not understand quoted
fields**, so a comma inside `"Smith, Ana"` breaks it, and it does not understand escapes. For real
CSV, use a real parser.

## The subshell, which is the invisible one

```
ana@vm:~/work/scripts$ cat subshell.sh
#!/bin/bash
total=0
printf '%s\n' 10 20 30 | while read -r n; do
  total=$((total + n))
done
echo "after the pipe, total is $total"
total=0
while read -r n; do
  total=$((total + n))
done < <(printf '%s\n' 10 20 30)
echo "after the redirect, total is $total"
ana@vm:~/work/scripts$ ./subshell.sh
after the pipe, total is 0
after the redirect, total is 60
```

Same arithmetic, same three numbers, and the first one says zero.

**Every stage of a pipeline runs in a subshell**, so the loop on the right of the `|` added
correctly — in a child process, which then exited and took `total` with it. Section 02's
`./script.sh` versus `source` is the same mechanism.

The fix is `< <(command)`, which is called **process substitution**. It makes a command's output
look like a file, so the loop reads from a redirect and stays in the current shell.

| | |
|---|---|
| `cmd \| while read …` | the loop is in a subshell. Variables do not survive it |
| `while read … done < file` | no subshell |
| `while read … done < <(cmd)` | no subshell. **This is the one to use** |

The space in `< <(` matters — `<(` is the process substitution and the first `<` is the redirect.

## The missing last line

```
ana@vm:/tmp/q2$ printf 'one\ntwo' > nonl.txt; cat -A nonl.txt
one$
twoana@vm:/tmp/q2$ while IFS= read -r l; do echo "[$l]"; done < nonl.txt
[one]
ana@vm:/tmp/q2$ while IFS= read -r l || [ -n "$l" ]; do echo "[$l]"; done < nonl.txt
[one]
[two]
```

`nonl.txt` has no newline on its last line — you can see it in the prompt running straight into
`two`. **The loop read one line and stopped**, because `read` hit end of file before a newline,
returned non-zero, and the `while` believed it.

`read` did still assign `two` to the variable. It just reported failure at the same time.

**`|| [ -n "$l" ]` is the fix**: keep going if the failed `read` nonetheless produced something.
Add it whenever the input might not come from a well-behaved program — a file somebody edited on
Windows, output from a tool that forgot its final newline.

## Reading from the terminal

`-p` prints a prompt, and it prints it to **standard error**, which you can watch:

```
ana@vm:/tmp/q2$ read -rp 'Continue? [y/N] ' answer 2>/tmp/q2/e.txt
y
ana@vm:/tmp/q2$ echo "answer=[$answer]"; echo '--- stderr file:'; cat -A /tmp/q2/e.txt
answer=[y]
--- stderr file:
Continue? [y/N] ana@vm:/tmp/q2$ [[ $answer == [Yy]* ]] && echo 'treated as yes' || echo 'treated as no'
treated as yes
```

The prompt was not on the screen at all — it went into the file, because `2>` caught it. Redirect
standard *output* instead and the prompt stays visible, which is the behaviour you want: a script
whose output is being captured still asks its question on the terminal.

`[[ $answer == [Yy]* ]]` is section 08's glob match, and it accepts `y`, `Y`, `yes` and `Yes`
while treating an empty answer — somebody just pressing return — as no. **Default to no** on
anything destructive.

One more thing to know: `read` inside a loop that is already reading a file will eat the file's
next line instead of waiting for the user — use `read -u 3` with an explicit descriptor, or
restructure.

And `-t 10` gives up after ten seconds, which is what turns a script that hangs forever in `cron`
into one that fails.
