---
title: Putting two files together, and finding the difference
version: 1
---

Everything so far worked on one stream. These five work on two, and each answers a different
question about how two lists relate.

| | |
|---|---|
| `paste` | put them **side by side**, line by line |
| `join` | match them **on a key**, like a database join |
| `comm` | what is in both, and what is in only one |
| `diff` | what changed, line by line |
| `split` | the opposite: one file into several |

## `paste`

```
ana@vm:~/work$ printf "ana\nbruno\ncarla\n" > /tmp/left.txt
ana@vm:~/work$ printf "1\n2\n3\n" > /tmp/right.txt
ana@vm:~/work$ paste /tmp/left.txt /tmp/right.txt
ana     1
bruno   2
carla   3
ana@vm:~/work$ paste -d, /tmp/left.txt /tmp/right.txt
ana,1
bruno,2
carla,3
```

Line one with line one, line two with line two, tab-separated unless `-d` says otherwise. **It does
not look at the content at all** — it is positional, so the two files must already be in the same
order.

`-s` is the other mode, and it is the one worth remembering:

```
ana@vm:~/work$ paste -sd, /tmp/left.txt
ana,bruno,carla
```

**`paste -sd,` turns a column into a comma-separated line**, which is the exact opposite of section
130's `tr , '\n'`. Section 126 used `paste -sd+ | bc` to add up a column, which is the same trick
with a different separator.

## `join`

```
ana@vm:~/work$ printf "ana north\nbruno north\ndiego south\n" | sort > /tmp/a.txt
ana@vm:~/work$ printf "ana 40\nbruno 12\nelena 7\n" | sort > /tmp/b.txt
ana@vm:~/work$ join /tmp/a.txt /tmp/b.txt
ana north 40
bruno north 12
```

`a.txt` has names and regions, `b.txt` has names and numbers, and `join` matched them on the first
field. `diego` and `elena` appear in only one file each, so they are not in the output.

**Both files must be sorted on the join field.** `join` reads them in step, like a merge, which is
what makes it work on files too large for memory — and what makes it silently wrong on unsorted
input. Sort both first, and section 127's locale warning applies: sort them the *same* way.

`-a` keeps the unmatched rows, which is an outer join:

```
ana@vm:~/work$ join -a1 -a2 -e "-" -o "0,1.2,2.2" /tmp/a.txt /tmp/b.txt
ana north 40
bruno north 12
diego south -
elena - 7
```

`-a1 -a2` keeps unmatched rows from both sides, `-e "-"` fills the gaps, and `-o` says which fields
to print: `0` is the key, `1.2` is field 2 of file 1, `2.2` is field 2 of file 2.

**That is as far as `join` is worth pushing.** It is fiddly, and the moment there are three files or
a composite key, the answer is `sqlite3`, which will read CSV directly and do this in SQL.

## `comm`

```
ana@vm:~/work$ cut -d" " -f1 /tmp/a.txt > /tmp/an.txt; cut -d" " -f1 /tmp/b.txt > /tmp/bn.txt
ana@vm:~/work$ comm -12 /tmp/an.txt /tmp/bn.txt
ana
bruno
ana@vm:~/work$ comm -23 /tmp/an.txt /tmp/bn.txt
diego
```

`comm` prints three columns: only in file 1, only in file 2, in both. The numbers **suppress** a
column, which reads backwards until you learn it:

| | |
|---|---|
| `comm -12` | suppress 1 and 2, leaving **both** — the intersection |
| `comm -23` | suppress 2 and 3, leaving **only in file 1** |
| `comm -13` | leaving **only in file 2** |

**`comm -23 a b` is "what is in a and not in b"**, and it is the fastest way to compare two lists of
anything — installed packages against a manifest, users against an expected set, files here against
files there.

Both files must be sorted, and unlike `join`, **`comm` tells you when they are not**:

```
ana@vm:~/work$ printf "b\na\nc\n" > /tmp/u1.txt; printf "a\nb\n" > /tmp/u2.txt
ana@vm:~/work$ comm /tmp/u1.txt /tmp/u2.txt
        a
                b
comm: file 1 is not in sorted order
a
c
comm: input is not in sorted order
```

It produces wrong output *and* complains, which is better than `join`, which produces wrong output
in silence. Sort both inputs and neither question arises.

## `diff`

```
ana@vm:~/work$ diff /tmp/an.txt /tmp/bn.txt
3c3
< diego
---
> elena
```

`3c3` is "line 3 changed to line 3". `<` is the first file, `>` is the second. `d` is deleted and
`a` is added.

**`diff -u` is the format you actually want**, because it is what patches and code review use:
context around the change, `-` and `+` instead of `<` and `>`.

The difference from `comm`: **`diff` cares about order and position, `comm` cares about membership.**
Two files with the same lines in a different order are identical to `comm -12` and completely
different to `diff`.

Other flags worth knowing: `-r` for whole directory trees, `-q` to say only whether they differ,
`-w` to ignore whitespace, and `-y` for a side-by-side view.

## `split`

```
split -l 10000 huge.log part_       # 10,000 lines each, part_aa, part_ab, …
split -b 100M archive.tar chunk_    # 100 MB each
split -n 4 file piece_              # four pieces
```

The opposite operation. Its uses are narrow and real: splitting something too large to send,
cutting a file into pieces for parallel processing, or getting a manageable sample.

`cat part_* > rejoined` puts it back, and the alphabetical suffixes are why that works.

## Which one to reach for

| | |
|---|---|
| two lists, what is in both | `comm -12` |
| two lists, what is only in the first | `comm -23` |
| two files, what changed | `diff -u` |
| two tables, matched on a key | `join`, or `sqlite3` |
| two columns into one table | `paste` |
| a column into one line | `paste -sd,` |

**And remember the precondition**: `join` and `comm` both require sorted input. `comm` complains
when it is not; `join` does not.
