---
title: `cut`, and where it stops being enough
version: 1
---

`cut` keeps some of each line and throws the rest away. It has exactly three modes and you will use
two of them.

```
ana@vm:~/work$ head -2 data/sales.csv
region,rep,quarter,units,revenue
north,ana,Q1,171,8721
ana@vm:~/work$ cut -d, -f2,5 data/sales.csv | head -4
rep,revenue
ana,8721
bruno,4116
carla,37084
```

| | |
|---|---|
| `-d` | the delimiter. **A single character**, and the default is TAB |
| `-f` | which fields: `3`, `2,5`, `2-4`, `2-` |
| `-c` | character positions instead of fields |

`-f2-` is "from the second to the end", which is the form you want when you do not know how many
fields there are:

```
ana@vm:~/work$ cut -d, -f2- data/sales.csv | head -3
rep,quarter,units,revenue
ana,Q1,171,8721
bruno,Q1,49,4116
```

## `-d` is one character, not a string

**There is no `-d ", "`.** `cut` takes a single character and that is a real limitation: a file
separated by `, ` or by runs of spaces cannot be cut directly.

The usual fix is section 130's `tr -s`, which squeezes runs of a character into one:

```
ana@vm:~/work$ head -2 logs/access.log | tr -s " " | cut -d" " -f1,6,7
10.0.1.6 "GET /static/app.js
10.0.1.11 "GET /
```

The other fix is to use `awk`, which splits on runs of whitespace by default and is section 132.

## On the log

```
ana@vm:~/work$ cut -d" " -f1,7,9 logs/access.log | head -3
10.0.1.6 /static/app.js 200
10.0.1.11 / 200
10.0.1.25 /index.html 404
```

Address, path, status, from lines of a hundred and fifty characters. **This is the workhorse use**:
narrow to the columns the question is about, then let `sort` and `uniq` do the counting.

## `-c`, for fixed-width text

```
ana@vm:~/work$ cut -c1-15 logs/access.log | head -3
10.0.1.6 - - [1
10.0.1.11 - - [
10.0.1.25 - - [
```

**That output is useless and it is the point.** Character positions only work when the columns
genuinely line up — `ls -l` output, some old reports, fixed-width exports from a mainframe. On
anything where field widths vary, `-c` cuts through the middle of things.

Where it does work it works well: `cut -c1-10` on a log whose lines all begin with a fixed-format
date is the fastest way to get the date out.

## Where `cut` stops

Three limits, and each one is a reason to move to `awk`:

**It cannot reorder:**

```
ana@vm:~/work$ cut -d, -f5,2 data/sales.csv | head -2
rep,revenue
ana,8721
ana@vm:~/work$ awk -F, 'NR<3 {print $5, $2}' data/sales.csv
revenue rep
8721 ana
```

I asked for field 5 then field 2 and `cut` gave me 2 then 5. **`cut` outputs fields in file order**
and there is no flag for it; `awk` prints them in the order you wrote.

**It cannot handle quoted fields:**

```
ana@vm:~/work$ printf "id,name\n1,\"Smith, John\"\n" | cut -d, -f2
name
"Smith
```

The comma inside the quotes is a comma to `cut`, so the name came out cut in half. **Nothing in
this lesson parses CSV correctly**; for real CSV with quoting, use a tool that knows the format —
`csvcut` from csvkit, `mlr`, or a few lines of python.

**It cannot handle variable whitespace** without `tr -s` first, as above.

The rule of thumb: **`cut` for a clean delimiter, `awk` for everything else.** `cut` is shorter to
type and faster on very large files, which is why it is still worth knowing.

## The header problem

Every example above printed the header line along with the data, because `cut` has no idea what a
header is. Two ways to drop it:

```
tail -n +2 data/sales.csv | cut -d, -f5      # skip line 1, then cut
awk -F, 'NR>1 {print $5}' data/sales.csv     # awk knows which line it is on
```

**`tail -n +2` is section 123's flag** and it is the one to reach for with `cut`. And having dropped
the header, you can add the arithmetic:

```
ana@vm:~/work$ cut -d, -f5 data/sales.csv | tail -n +2 | paste -sd+ | bc
573278
```

Four programs to add up a column: take the field, drop the header, join the lines with `+` signs,
and hand the resulting sum to a calculator. It works, it is genuinely how people do this, and
section 132 does the same thing in one:

```
ana@vm:~/work$ awk -F, 'NR>1 {s+=$5} END {print s}' data/sales.csv
573278
```

Same number, one process instead of four, and no `bc` to install.
