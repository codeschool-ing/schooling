---
title: Sort, group and measure — `sort | uniq -c` with the sort built in
version: 1
---

Lesson 8's closing rule was that `sort` before `uniq -c` is not optional, because
`uniq` collapses adjacent duplicates and quietly gives a wrong answer otherwise.

**`Group-Object` does not have that failure mode**, because it does not work on
adjacency — it works on values.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Group-Object region | Select-Object Name, Count
Name  Count
----  -----
east      8
north     8
south     8
west      8
```

One command where lesson 8 needed `cut -d, -f1 | sort | uniq -c`, and no
ordering precondition to forget.

`Group-Object` returns a group object per distinct value, with `Name`, `Count`
and a `Group` property holding the members — so you can count them, or reach
into them:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Group-Object region | Select-Object -First 1 Name, Count, @{n="first rep";e={$_.Group[0].rep}}
Name Count first rep
---- ----- ---------
east     8 elena
```

That third column is a **calculated property**: a hashtable with `n` for the name
and `e` for an expression evaluated per object. `Select-Object` and
`Format-Table` both take them, and it is how you add a column that no cmdlet
produced — a size in megabytes, an age in days, a field pulled out of a nested
object.

## `Sort-Object`

```
PS /home/ana/work/ps> Import-Csv sales.csv | Sort-Object { [int]$_.revenue } -Descending | Select-Object -First 3 rep, revenue
rep    revenue
---    -------
ana    43731
felipe 41574
carla  37084
```

`Sort-Object` takes property names, or a block that computes the key — and the
`[int]` is the previous section's trap arriving again. Here is the same sort
without it:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Sort-Object revenue -Descending | Select-Object -First 3 rep, revenue
rep  revenue
---  -------
ana  8721
ana  8601
hugo 7257
```

**The largest revenue in the file is 43731 and it is not in that table.** Sorted
as text, `8721` is the biggest thing there is, because `8` beats `4`. No error,
a perfectly plausible answer, and the wrong three rows.

| | |
|---|---|
| `Sort-Object Name` | by a property |
| `Sort-Object Length -Descending` | reversed |
| `Sort-Object region, rep` | two keys, in order. Like `sort -k` |
| `Sort-Object { [int]$_.units }` | by something computed |
| `Sort-Object -Unique` | sort and drop duplicates |

**`Sort-Object` is a blocking stage.** It cannot emit anything until it has seen
everything, so a pipeline with a sort in it stops streaming at that point. That
is true of `sort` in bash too, and it is the reason `Select-Object -First 3`
belongs *after* the sort and not before it.

## `Measure-Object`

```
PS /home/ana/work/ps> Import-Csv sales.csv | Measure-Object -Property units -Sum -Average
Count             : 32
Average           : 199.34375
Sum               : 6379
Maximum           :
Minimum           :
StandardDeviation :
Property          : units
```

`wc -l`, `awk '{s+=$4} END {print s}'` and an average, in one command. The empty
rows are the statistics that were not asked for — `-Maximum` and `-Minimum` are
separate switches, and `-AllStats` turns on everything.

Note `Count` is 32, not 33: the header row became property names, not an object.

And note what happened quietly: `units` is a **string** property, and
`Measure-Object` summed it anyway, because it converts what it is given. That is
convenient here and it is the same coercion that gave the wrong answer in the
previous section — it converts for arithmetic and does not for comparison.

With no `-Property`, `Measure-Object` just counts, which makes
`… | Measure-Object | Select-Object Count` the standard way to ask "how many came
out of this pipeline".

## Why not `$x.Count`

```sh
(Import-Csv sales.csv).Count                        # works — 32
(Get-ChildItem sales.csv).Count                     # works — 1
```

`.Count` is fine when you already have the collection. It is not fine when the
command might return **nothing or exactly one thing**, which in older PowerShell
returns something with no `.Count` at all. `Measure-Object` counts a stream of
zero, one or a million identically, and `@( … ).Count` forces an array first.

## The four together

```
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 20000 } | Group-Object region | Sort-Object Count -Descending | Select-Object Name, Count
Name  Count
----  -----
east      4
north     4
south     3
west      1
```

Filter, group, sort, take. **That shape answers most questions you will ask a
machine**, and it is the same shape as lesson 8's `grep | cut | sort | uniq -c |
sort -rn` — with the parsing removed and the ordering precondition gone.

A pipeline can be broken across lines after a `|`, as above. PowerShell knows the
statement is not finished, so there is no `\` at the end of the line.
