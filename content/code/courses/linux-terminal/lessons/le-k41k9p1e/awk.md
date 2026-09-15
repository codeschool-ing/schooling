---
title: `awk`, a programming language you write on one line
version: 1
---

`awk` reads a line, splits it into fields, and runs your code on it. That is the whole model, and it
makes `awk` the tool that does what `cut`, `grep` and a calculator would have to be combined to do.

```
ana@vm:~/work$ awk '{print $1}' logs/access.log | head -2
10.0.1.6
10.0.1.11
ana@vm:~/work$ awk '{print $9, $7}' logs/access.log | head -3
200 /static/app.js
200 /
404 /index.html
```

**`$1` is the first field, `$0` is the whole line, `$NF` is the last one.** Fields are split on runs
of whitespace by default — which is already better than `cut`, since it needs no `tr -s` on padded
text.

And the second command reordered the fields, which section 126 showed `cut` cannot do.

## The shape of a program

```
awk 'pattern { action }'
```

Either half can be left out:

| | |
|---|---|
| `{ print $1 }` | no pattern: do it for every line |
| `$9 == 500` | no action: print the whole line when true |
| `/api/ { c++ }` | both |

```
ana@vm:~/work$ awk '$9 == 500 {print $7}' logs/access.log | sort | uniq -c
      2 /
      1 /api/orders/new
      5 /api/reports
      2 /api/users
      1 /favicon.ico
      7 /health
      1 /index.html
      2 /static/app.js
ana@vm:~/work$ awk '$9 >= 400' logs/access.log | wc -l
63
```

**`$9 >= 400` is the thing `grep` cannot do**, because it is arithmetic on a field rather than text
matching. Here is the difference, measured:

```
ana@vm:~/work$ awk '$9 >= 400 && $9 < 500' logs/access.log | wc -l
42
ana@vm:~/work$ grep -c ' 4[0-9][0-9] ' logs/access.log
46
ana@vm:~/work$ grep ' 4[0-9][0-9] ' logs/access.log | awk '$9 < 400 || $9 >= 500' | head -2
10.0.1.19 - - [14/Sep/2026:06:03:17 +0000] "GET /static/app.css HTTP/1.1" 200 451 "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/18.1" 87
10.0.1.20 - - [14/Sep/2026:07:55:33 +0000] "GET /favicon.ico HTTP/1.1" 200 485 "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36" 59
```

**Forty-two against forty-six, and the four extras are `200` responses.** Their *byte counts* were
451 and 485, which the pattern matched because it has no idea which number is the status. `awk` was
asked about field nine and `grep` was asked about a shape.

## The built-in variables

| | |
|---|---|
| `NR` | the record number — the line you are on |
| `NF` | the **number of fields** on this line |
| `FS` | the input field separator. `-F,` sets it |
| `OFS` | the output field separator, used by `print a, b` |

```
ana@vm:~/work$ awk 'END {print NR}' logs/access.log
1200
```

`END` runs once after the last line, and `BEGIN` runs once before the first. **`END {print NR}` is
`wc -l`**, and the point of knowing that is that `NR` is available inside the body too:
`NR > 1` skips a header, `NR % 100 == 0` samples every hundredth line.

## The check worth running on any new file

```
ana@vm:~/work$ awk '{print NF}' logs/access.log | sort -u
12
15
18
20
```

**Four different field counts, on a file where every line looks the same shape.** That is not
corruption: the user-agent string is in quotes and contains spaces, and `awk` splits on whitespace
without caring about quotes.

Which is the warning this section has to carry. **`$7` is the path on every line of this log** —
`awk '{print $7}' | grep -cv '^/'` returns `0` — because the variation starts after it. `$11` is
not:

```
ana@vm:~/work$ awk '{print $11}' logs/access.log | sort | uniq -c | sort -rn
    461 "Mozilla/5.0
    442 "kube-probe/1.29"
    154 "curl/8.5.0"
    143 "python-requests/2.32.3"
```

Three of those are whole user-agent strings and one is the **first word of a longer one**. Any field
at or after a free-text field is unreliable; `$NF` stays reliable, because it counts from the other
end.

`awk '{print NF}' file | sort -u` on an unfamiliar file takes a second and tells you whether
positional fields are safe at all.

## Arithmetic, which is why people reach for it

```
ana@vm:~/work$ awk '{n++; bytes += $10} END {print n, bytes, bytes/n}' logs/access.log
1200 14262906 11885.8
```

Twelve hundred requests, fourteen megabytes, an average of about twelve kilobytes each.
**Variables need no declaration and start at zero**, which is what makes one-liners this short.

```
ana@vm:~/work$ awk -F, 'NR>1 {s+=$5} END {print s}' data/sales.csv
573278
```

Section 126 did that with four processes and `bc`.

## Associative arrays, which is why it replaces `sort | uniq -c`

```
ana@vm:~/work$ awk -F, 'NR>1 {rev[$1] += $5} END {for (r in rev) print r, rev[r]}' data/sales.csv | sort
east 144250
north 147239
south 167399
west 114390
```

**`rev[$1] += $5` is a group-by and a sum**, in one expression, in one pass. An array subscripted by
a string, created on first use.

That is the pattern to keep. Counting is the same thing with `++`:

```
awk '{c[$7]++} END {for (p in c) print c[p], p}' logs/access.log | sort -rn | head
```

Section 128 showed that giving the same answer as `sort | uniq -c`, without the sort.

**The order of `for (k in arr)` is undefined**, which is why both of those end in `| sort`.

## Formatting

```
ana@vm:~/work$ awk '$NF > 3000 {printf "%-22s %6s ms  %s\n", $1, $NF, $7}' logs/access.log | head -4
10.0.1.21                5833 ms  /api/reports
10.0.1.38                3370 ms  /api/reports
198.51.100.10            3496 ms  /api/reports
10.0.1.29                4072 ms  /api/reports
```

`printf` is the C one: `%s` string, `%d` integer, `%.2f` two decimal places, `%-22s` left-aligned in
22 columns. **`printf` needs its own `\n`**; `print` adds one.

```
ana@vm:~/work$ awk 'BEGIN {FS=","; OFS=" | "} NR<4 {print $2, $4}' data/sales.csv
rep | units
ana | 171
bruno | 49
```

Setting `FS` and `OFS` in `BEGIN` is the alternative to `-F`, and it is the only way to set the
*output* separator. Note that `print $2, $4` uses `OFS` for the comma and `print $2 $4` — no comma —
concatenates with nothing between them.

## Patterns that are regular expressions

```
ana@vm:~/work$ awk '/api/ {c++} END {print c " api requests"}' logs/access.log
260 api requests
```

`/pattern/` matches against the whole line, `$7 ~ /pattern/` against one field, and `!~` is "does
not match". The pattern language is section 125's extended syntax.

## When to stop

`awk` has functions, `getline`, multiple files, `ARGV`, string functions and output redirection. It
is a real language and the manual is a hundred pages.

**The line to draw is this**: when the program needs a second condition and a third variable, and
you have started counting quotes, it has become a program. Write it in a file — which is lesson 9 —
or in python. A twelve-line `awk` one-liner is impressive and nobody will ever change it safely.

The `awk` worth having in your fingers is five patterns:

```
awk '{print $3}'                             # a column
awk '$9 >= 400'                              # a numeric condition
awk -F, 'NR>1 {s+=$5} END {print s}'         # a sum
awk '{c[$7]++} END {for(k in c) print c[k], k}'   # a group-by count
awk '{print NF}' file | sort -u              # is this file the shape I think
```
