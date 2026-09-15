---
title: `sort`, and the flag that is not optional
version: 1
---

`sort` orders lines. The default order is **alphabetical, by the whole line**, and the first thing
to know is when that is wrong.

```
ana@vm:~/work$ cut -d, -f4 data/sales.csv | tail -n +2 | sort | head -4
109
113
122
123
ana@vm:~/work$ cut -d, -f4 data/sales.csv | tail -n +2 | sort -n | head -4
26
31
40
49
```

**Same numbers, two answers, and the first one is wrong.** Alphabetically `109` comes before `26`,
because `1` comes before `2` — and it is correct alphabetical order, applied to something that is
not text.

**`-n` is the flag you will forget and then have to learn twice.** Any time the thing you are
sorting is a number — a count, a size, a duration, a port — it needs `-n`.

| | |
|---|---|
| `-n` | numeric |
| `-h` | **human** numeric: understands `1K`, `2.5M`, `3G`. For `du -h` output |
| `-r` | reverse |
| `-u` | unique: drop duplicate lines as it goes |
| `-t` | the field separator |
| `-k` | which field, or fields |

## Sorting by a field

```
ana@vm:~/work$ sort -t, -k5 -rn data/sales.csv | head -3
north,ana,Q2,387,43731
east,felipe,Q4,338,41574
south,carla,Q1,292,37084
```

`-t,` sets the separator, `-k5` is the fifth field, `-rn` is reverse numeric. The biggest revenue
first.

**`-k` takes a range, and the range matters more than it looks.** `-k5` means "from field 5 to the
end of the line", not "field 5". For a single field you want `-k5,5`:

```
ana@vm:~/work$ sort -t, -k1,1 -k3,3 data/sales.csv | head -4
east,elena,Q1,31,3348
east,felipe,Q1,338,24336
east,elena,Q2,332,20584
east,felipe,Q2,109,12862
```

Region first, then quarter within region. **Two `-k` options are two sort keys**, applied in order,
which is how you express "group by this, then order by that".

And a modifier can go on one key rather than the whole command: `-k5,5nr` sorts that field
numerically in reverse while leaving the others alone.

## `-u` and the thing it does not do

```
ana@vm:~/work$ sort -u logs/app.log
app handled a request
app ready
app started
```

Thirty lines in, three out. `sort -u` is `sort | uniq` in one process, and it is the right choice
when you only want the distinct values.

**It is not the right choice when you want counts**, because it throws away the information
`uniq -c` needs. That is section 128.

## Locale, and why `sort` sometimes disagrees with itself

```
ana@vm:~/work$ printf "b\na\nB\nA\n" | sort
A
B
a
b
ana@vm:~/work$ printf "b\na\nB\nA\n" | LC_ALL=C sort
A
B
a
b
```

**The two agree here, and they do not always.** This machine's locale is `C.UTF-8`, which sorts by
byte value, so `LC_ALL=C` changes nothing. On a machine set to `en_US.UTF-8` the first command gives
`a A b B` — case-insensitive, letter by letter — and the second still gives `A B a b`.

That matters in exactly one situation and it is a bad one: **a script that compares sorted output
between two machines.** `comm` and `join` in section 133 both require their inputs to be sorted *the
same way*, and two machines with different locales produce different orders from the same data.

The fix is to be explicit. **`LC_ALL=C sort` in a script** makes the order deterministic, and it is
also faster, because byte comparison is cheaper than collation.

## Big files

`sort` holds what it needs in memory and spills the rest to temporary files, so it works on inputs
larger than RAM. Two flags for when that matters:

```
sort -S 2G big.log            # use this much memory before spilling
sort -T /var/tmp big.log      # put the temporary files here
```

**`-T` is the one that saves you**, on a machine where `/tmp` is small and the file is not. The
error when it runs out is `No space left on device` pointing at a directory you did not choose.

And `sort --parallel=4` uses several cores, which on a large file is a real difference.

## The two habits

**Reduce before you sort.** `grep` and `cut` first: sorting twelve hundred four-character fields is
cheaper than sorting twelve hundred hundred-and-fifty-character lines, and on a large log the ratio
is the same but the numbers are minutes.

**And check `-n` every single time.** The failure is silent, the output looks sorted, and `109`
before `26` is easy to miss in a list of two hundred.
