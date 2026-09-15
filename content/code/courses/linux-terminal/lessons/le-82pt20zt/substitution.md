---
title: `$( )` and `$(( ))`, which look alike and are not related
version: 1
---

Two constructions, one character apart, doing entirely different things.

| | |
|---|---|
| `$(command)` | run a command, become its **output** |
| `$(( expression ))` | evaluate arithmetic, become the **number** |

## `$( )` — command substitution

```
ana@vm:~/work/scripts$ now=$(date +%F); echo "today is $now"
today is 2026-09-15
ana@vm:~/work/scripts$ n=$(wc -l < ~/work/logs/access.log); echo "[$n]"
[1200]
```

The command runs in a subshell, its standard output is captured, and that text replaces the whole
`$( )`. Standard error is **not** captured — it goes to the terminal as usual, which is usually
what you want and is occasionally why an error message appears in the middle of your output.

Note `wc -l < file` rather than `wc -l file`:

```
ana@vm:~/work/scripts$ n=$(wc -l ~/work/logs/access.log); echo "[$n]"
[1200 /home/ana/work/logs/access.log]
```

Given a filename, `wc` prints the name too, and that is not a number. **Feeding the file in on
standard input is how you get a bare count out of `wc`**, and the same trick applies to any tool
that labels its output when it knows the filename.

### Trailing newlines are stripped

```
ana@vm:~/work/scripts$ printf 'a\n\n\n' > /tmp/q2/tn.txt; v=$(cat /tmp/q2/tn.txt); echo "[$v]"
[a]
```

Three newlines went in, none came out. **`$( )` strips every trailing newline**, which is why
`n=$(wc -l < file)` gives you `1200` and not `1200` followed by a line break.

This is nearly always helpful and is worth knowing about when it is not — reading a file into a
variable to write it back out loses the final newline, and a file without one causes the trouble in
section 148.

### Backticks

```
ana@vm:~/work/scripts$ old=`date +%F`; echo "backticks give $old"
backticks give 2026-09-15
```

`` `command` `` is the older spelling and it still works everywhere. Use `$( )` anyway:

```
ana@vm:~/work/scripts$ echo "nested: $(basename $(dirname /usr/local/bin/node))"
nested: bin
```

**Nesting is the reason.** The backtick version needs `\`` escaping inside itself and becomes
unreadable at two levels. `$( )` nests by being properly parenthesised.

`shellcheck` flags backticks (SC2006) and suggests the replacement, which is one of the few style
rules worth taking without argument.

### It is an expansion, so quote it

`"$(cmd)"`, for the reasons in section 141. Unquoted, the output is split on whitespace and globbed.

## `$(( ))` — arithmetic

```
ana@vm:~/work/scripts$ echo $(( 7 / 2 )) $(( 7 % 2 )) $(( 2 ** 10 ))
3 1 1024
ana@vm:~/work/scripts$ i=5; echo $(( i * 3 ))
15
```

**Integer arithmetic only.** `7 / 2` is 3, not 3.5, and there is no rounding — it truncates.

Inside `$(( ))` a variable does not need its `$`: `i * 3` works because the whole thing is an
arithmetic context. Both spellings are fine and `$i * 3` is clearer to a reader who has not
memorised this.

The operators are C's: `+ - * / %`, `**` for power, `++ --`, `+= -=`, `== != < > <= >=`, `&& || !`,
and the ternary `a ? b : c`.

Comparisons produce 1 and 0:

```
ana@vm:~/work/scripts$ echo $(( 10 > 3 )) $(( 10 < 3 ))
1 0
```

Which is backwards from exit statuses, where 0 is success — so `$(( ))` is for computing numbers,
and `[ ]` or `(( ))` is for deciding.

`(( ))` without the `$` is the statement form. It evaluates and sets the **exit status**, with zero
meaning the expression was non-zero — so it reads naturally in an `if`:

```
ana@vm:~/work/scripts$ echo $(( 5 > 3 )); (( 5 > 3 )); echo "exit $?"
1
exit 0
ana@vm:~/work/scripts$ echo $(( 3 > 5 )); (( 3 > 5 )); echo "exit $?"
0
exit 1
```

Same expression, two forms, opposite numbers. `$(( ))` gives the value; `(( ))` translates it into
success and failure.

And that translation is a trap, which is best met here rather than in production:

```
ana@vm:~/work/scripts$ cat counttrap.sh
#!/bin/bash
set -e
count=0
(( count++ ))
echo "count is now $count"
echo "never reached"
ana@vm:~/work/scripts$ ./counttrap.sh; echo "exit $?"
exit 1
```

**The script printed nothing at all.** `count++` is post-increment: it evaluates to the value
*before* incrementing, which was 0, which `(( ))` reports as failure, which `set -e` treats as an
error. The counter was incremented and the script died on the same line.

```
ana@vm:~/work/scripts$ count=0; (( count++ )); echo "status $?"
status 1
ana@vm:~/work/scripts$ count=0; (( ++count )); echo "status $?"
status 0
ana@vm:~/work/scripts$ count=0; count=$((count+1)); echo "status $? count $count"
status 0 count 1
```

Three ways to add one. **Use the third** — `count=$((count+1))` is an assignment, and an assignment
always succeeds. `(( count++ )) || true` also works and says less about why.

### The leading zero

```
ana@vm:~/work/scripts$ echo $(( 08 + 1 ))
bash: 08: value too great for base (error token is "08")
ana@vm:~/work/scripts$ echo $(( 10#08 + 1 ))
9
```

**A number with a leading zero is octal**, and there is no digit 8 in octal.

This is not a curiosity, because the numbers most likely to arrive with a leading zero are dates:

```
ana@vm:~/work/scripts$ d=08; echo $(( d + 1 ))
bash: 08: value too great for base (error token is "08")
```

`date +%m` gives `08` in August and `09` in September, `date +%d` gives `01` on the first, and
every one of those is a script that works for ten months of the year. **`10#` forces base ten** and
is the fix; stripping the zero with `${x#0}` is the other one, and it breaks on `00`.

### Fractions

```
ana@vm:~/work/scripts$ echo 'scale=3; 7/2' | bc
3.500
```

`$(( ))` cannot do this at all. `bc` can, `awk` can, and section 129 covered both. **If your script
needs a percentage or an average, one of those is doing the arithmetic**, not bash.

## `let` and `expr`

You will see these in older scripts:

```sh
let "n = n + 1"          # bash, older, no advantage over (( n++ ))
n=$(expr $n + 1)         # a separate process, per addition
```

`expr` is a program. In a loop it forks once per iteration, where `$(( ))` is free. Neither is
wrong; neither is worth writing today.
