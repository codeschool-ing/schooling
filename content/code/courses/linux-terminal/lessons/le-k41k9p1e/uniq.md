---
title: `uniq`, which does not do what its name says
version: 1
---

`uniq` collapses **adjacent** identical lines. It is not a de-duplicator; it is a run-length
counter, and the difference is the most common bug in one-liners.

```
ana@vm:~/work$ printf "a\na\nb\na\n" | uniq
a
b
a
ana@vm:~/work$ printf "a\na\nb\na\n" | sort | uniq
a
b
```

**Three lines out of a command called `uniq`.** The two `a`s at the front were adjacent and
collapsed; the `a` at the end was not next to them, so it survived.

**This is not a bug and it does not warn you.** On unsorted input `uniq` gives a wrong answer that
looks like a right one, and the only defence is the habit: **`sort` before `uniq`, always.**

The reason it works this way is that it lets `uniq` handle a stream of any size in constant memory.
A real de-duplicator would have to remember every line it had seen.

## `-c`, which is the whole point

```
ana@vm:~/work$ cut -d" " -f7 logs/access.log | sort | uniq -c | sort -rn | head -6
    287 /health
    261 /
    147 /api/orders
    110 /static/app.js
    104 /static/app.css
     76 /index.html
```

**`sort | uniq -c | sort -rn` is the single most useful pipeline in this lesson**, and it is worth
learning as one unit: *count the distinct values and show me the most common.*

Read it as three steps: group identical things together, count each group, order by the count.

It answers, with only the field changed:

| | |
|---|---|
| which paths are busiest | `cut -d" " -f7` |
| which addresses are noisiest | `cut -d" " -f1` |
| which status codes came back | `cut -d" " -f9` |
| which commands you type most | `history \| awk '{print $2}'` |

**The second `sort -rn` is where section 09's `-n` earns its keep.** `uniq -c` puts the count
first, so sorting without `-n` would put `100` before `99`.

## `-d` and `-u`, which are opposites

```
ana@vm:~/work$ cut -d" " -f1 logs/access.log | sort | uniq -d | head -3
10.0.1.10
10.0.1.11
10.0.1.12
ana@vm:~/work$ cut -d" " -f1 logs/access.log | sort | uniq -u | head -3
```

| | |
|---|---|
| `-d` | only lines that appear **more than once** |
| `-u` | only lines that appear **exactly once** |

The second command printed nothing, and that is an answer: **every address in this log appears more
than once.** An empty result from `uniq -u` says "no value here is unique", which on a list of user
IDs or checksums is often exactly what you wanted to know.

`-d` is the duplicate finder. `sort file | uniq -d` on a list of anything that should be unique —
IDs, email addresses, filenames — names the collisions in one line.

## `-i` and `-f`

`uniq -i` ignores case. `uniq -f1` ignores the first field when comparing, which is how you collapse
lines that differ only in a leading timestamp or count:

```
sort file | uniq -c | sort -rn | uniq -f1 -d
```

That is niche. The three to remember are `-c`, `-d` and `-u`.

## The ordering trap, in full

Here is the bug in the wild. You want the ten busiest paths:

```
ana@vm:~/work$ cut -d" " -f7 logs/access.log | uniq -c | sort -rn | head -4
      5 /
      5 /
      5 /
      4 /health
```

The same pipeline **with the `sort` left out**. `uniq -c` on unsorted input counts *runs*, so a path
that appears two hundred and sixty times scattered through the file produces dozens of separate
small counts — and `/` appears three times in four lines of output, each time claiming to have been
seen five times.

Compare it with the correct version at the top of this section: `287 /health`, `261 /`. Not one
number here is right.

**And nothing in that output looks incorrect at a glance.** The counts are plausible and the paths
are real. The `/` repeating three times is the only tell, and on a listing of twenty lines you
would not see it. This is the argument for running a new pipeline on a few lines first, where you
can check the answer by eye.

## Counting without `uniq`

`awk` can count in one pass, unsorted, because it has an associative array:

```
ana@vm:~/work$ awk '{c[$7]++} END {for (p in c) print c[p], p}' logs/access.log | sort -rn | head -4
287 /health
261 /
147 /api/orders
110 /static/app.js
```

Same answer as the top of this section, and no `sort` before the counting — so on a very large file
it is substantially faster, and it does not need the input grouped.

**`sort | uniq -c` is easier to type and `awk` is faster on big inputs.** Both are correct; section
14 is the second one.