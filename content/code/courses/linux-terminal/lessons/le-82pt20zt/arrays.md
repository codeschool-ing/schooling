---
title: Arrays, for when a list of words is not enough
version: 1
---

A plain variable holds one string. Put a list of filenames in one, separated by spaces, and you
have re-created every problem in section 141. An array holds a list of values and keeps the
boundaries.

```
ana@vm:/tmp/q2$ hosts=(web01 web02 'db 01')
ana@vm:/tmp/q2$ echo "${hosts[0]} / ${hosts[2]}"
web01 / db 01
ana@vm:/tmp/q2$ echo "count: ${#hosts[@]}"
count: 3
```

| | |
|---|---|
| `arr=(a b c)` | create. Spaces separate, quotes group |
| `${arr[0]}` | one element. **Indexes start at zero** |
| `${arr[@]}` | all of them |
| `${#arr[@]}` | how many |
| `${!arr[@]}` | the indexes |
| `arr+=(d)` | append |

**Every one of those needs braces.** `$arr[0]` is the variable `arr` followed by `[0]`, which is
not what you want and does not error.

And `$arr` on its own is `${arr[0]}` — the first element, silently:

```
ana@vm:/tmp/q2$ arr=(one two three); echo "[$arr]"; echo "[${arr[0]}]"
[one]
[one]
```

An array that looks like it lost everything after the first item usually just lost its `[@]`.

## `"${arr[@]}"`, with the quotes

Exactly the same rule as `"$@"` in section 142, for exactly the same reason:

```
ana@vm:/tmp/q2$ for h in "${hosts[@]}"; do echo "[$h]"; done
[web01]
[web02]
[db 01]
ana@vm:/tmp/q2$ for h in ${hosts[@]}; do echo "[$h]"; done
[web01]
[web02]
[db]
[01]
```

**`"${arr[@]}"` gives one word per element.** Unquoted, the elements are then split again and the
three-element array becomes four words.

`${arr[*]}` in double quotes joins everything into one string, like `"$*"`. It is for printing, not
for iterating.

## Growing one

```
ana@vm:/tmp/q2$ hosts+=(cache01); echo "${hosts[@]}"
web01 web02 db 01 cache01
ana@vm:/tmp/q2$ echo "indices: ${!hosts[@]}"
indices: 0 1 2 3
ana@vm:/tmp/q2$ unset 'hosts[1]'; echo "indices now: ${!hosts[@]}"
indices now: 0 2 3
```

**`unset` leaves a hole.** Indexes 0, 2 and 3, with nothing at 1 — bash arrays are sparse, so
`${#arr[@]}` is the number of elements that exist, not the largest index plus one. Never loop over
an array with `for ((i=0; i<${#arr[@]}; i++))`; loop over `"${arr[@]}"`, or over `"${!arr[@]}"` if
you need the indexes.

## Filling one from a glob

```
ana@vm:/tmp/q2$ cd /tmp/q2 && files=(*.txt); echo "${#files[@]} files: ${files[*]}"
2 files: nonl.txt tricky.txt
```

**`files=(*.log)` is the safe way to hold a list of filenames**, because the shell built the list
and each name is one element however many spaces it contains. Combined with `shopt -s nullglob`
from section 147, `${#files[@]}` is then a true count, including zero.

From a command's output, the spelling is `mapfile`:

```
ana@vm:/tmp/q2$ mapfile -t lines < ~/work/logs/app.log; echo "${#lines[@]} lines"
30 lines
ana@vm:/tmp/q2$ mapfile users < /etc/passwd; echo "[${users[0]}]"
[root:x:0:0:root:/root:/bin/bash
]
```

**`-t` strips the trailing newline** from each line. Without it, every element ends in one — look
at where the closing bracket landed. `mapfile` is also called `readarray`; they are the same
builtin. It reads from a redirect, so `mapfile -t x < <(cmd)` is how you fill one from a command.

Do not use `arr=($(command))` for this. It splits on whitespace and globs the results — the same
bug as `for f in $(ls)`, in a form that looks more deliberate.

## Passing an array to a command

```sh
rsync_opts=(-a --delete --exclude '*.tmp')
rsync "${rsync_opts[@]}" src/ dst/
```

This is the answer to the `cmd $FLAGS` problem from section 141. The string version breaks the
moment one option has a space in it — `--exclude '*.tmp'` becomes three arguments — and the array
version cannot, because each element stays one argument.

**When you find yourself building a command line in a variable, build it in an array instead.**

## Associative arrays

```
ana@vm:/tmp/q2$ declare -A color; color[apple]=red; color[lime]=green
ana@vm:/tmp/q2$ echo "${color[apple]}"; for k in "${!color[@]}"; do echo "$k=${color[$k]}"; done
red
lime=green
apple=red
```

**`declare -A` first, always.** Here is what happens without it:

```
ana@vm:/tmp/q2$ unset c; c[apple]=red; c[lime]=green; declare -p c
declare -a c=([0]="green")
ana@vm:/tmp/q2$ unset d; declare -A d; d[apple]=red; d[lime]=green; declare -p d
declare -A d=([lime]="green" [apple]="red" )
```

`declare -a` — lower case — is an *indexed* array, and bash evaluated `apple` and `lime` as
arithmetic, where an unset name is zero. Both assignments went to element 0 and the second
overwrote the first. **No error, no warning: one value where you expected a dictionary**, and
`declare -p` is how you find out.

`${!color[@]}` gives the keys. **The order is not the insertion order** and is not sorted; it is
whatever the hash table produces. If you need an order, pipe the keys through `sort`.

Associative arrays are bash 4 and later. That is everything current, and it is not macOS's system
bash, which is still 3.2 for licensing reasons — if a script needs to run there, it does not have
them.

## When an array is the wrong answer

Bash arrays are one-dimensional and hold strings. There is no array of arrays, no array in a
variable you can pass to a function by name without `declare -n` tricks, and no way to store
anything structured.

**A script that wants a list of records, each with fields, has outgrown bash.** That is not a
criticism of bash; it is the boundary the closing video draws.
