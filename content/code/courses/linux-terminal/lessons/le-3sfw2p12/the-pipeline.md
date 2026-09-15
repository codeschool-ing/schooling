---
title: The pipeline, and the moment text becomes objects
version: 1
---

`|` does what it does in bash: the thing on the left feeds the thing on the
right. What travels down it is the difference.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Select-Object -First 3
region  : north
rep     : ana
quarter : Q1
units   : 171
revenue : 8721

region  : north
rep     : bruno
quarter : Q1
units   : 49
revenue : 4116

region  : south
rep     : carla
quarter : Q1
units   : 292
revenue : 37084
```

**`Import-Csv` is the moment text becomes objects.** It read the header row,
made a property out of each column name, and emitted one object per line.
Everything after it in the pipeline works on names rather than positions.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Get-Member -MemberType NoteProperty
   TypeName: System.Management.Automation.PSCustomObject

Name    MemberType   Definition
----    ----------   ----------
quarter NoteProperty string quarter=Q1
region  NoteProperty string region=north
rep     NoteProperty string rep=ana
revenue NoteProperty string revenue=8721
units   NoteProperty string units=171
```

Read the right-hand column carefully, because the next section turns on it:
**every one of those is a `string`**. `Import-Csv` does not guess types. `171` is
the three characters `171`.

## One at a time, not all at once

A bash pipeline runs its stages concurrently as processes, connected by a buffer.
A PowerShell pipeline runs in one process, and passes **one object at a time**
down the whole chain before starting on the next.

That is why `Select-Object -First 3` above stopped `Import-Csv` after three rows
rather than reading the file and throwing the rest away — the same idea as
`head` closing the pipe in lesson 8, arrived at differently. It is easy to prove
to yourself:

```
PS /home/ana/work/ps> 1..1000000 | ForEach-Object { $_ } | Select-Object -First 3
1
2
3
```

**A million objects were not made.** Three went through, `Select-Object` had what
it was asked for, and it stopped the pipeline.

It also means a long-running command's results appear as they are produced,
which is what makes `Get-ChildItem -Recurse | Where-Object …` on a large tree
usable.

## `$_`, the current object

```
PS /home/ana/work/ps> 1..4 | ForEach-Object { $_ * $_ }
1
4
9
16
```

**`$_` is whatever is going past right now.** It is `$PSItem` written out in
full, and it appears in every block that runs once per object: `ForEach-Object`,
`Where-Object`, `switch`.

`1..4` is a range, and it is an array of integers rather than four lines of text.

## `Select-Object` does three different jobs

```
PS /home/ana/work/ps> Get-ChildItem | Select-Object Name, Length | ConvertTo-Json
[
  {
    "Name": "access.log",
    "Length": 148233
  },
  {
    "Name": "sales.csv",
    "Length": 788
  }
]
```

| | |
|---|---|
| `Select-Object Name, Length` | keep these properties, drop the rest. Like `cut` |
| `Select-Object -First 3` | keep the first three objects. Like `head` |
| `Select-Object -ExpandProperty Name` | **the values, not objects that have them** |

The third is the one people trip over:

```
PS /home/ana/work/ps> (Get-ChildItem | Select-Object Name)[0].GetType().Name
PSCustomObject
PS /home/ana/work/ps> (Get-ChildItem | Select-Object -ExpandProperty Name).GetType().Name
Object[]
PS /home/ana/work/ps> Get-ChildItem | Select-Object -ExpandProperty Name
access.log
sales.csv
```

`Select-Object Name` gives you **objects that have a `Name`**; `-ExpandProperty
Name` gives you **the values**. When something downstream says it cannot find
what you handed it, this is usually why.

And `ConvertTo-Json` is worth noticing for its own sake: turning objects into
JSON is one cmdlet, and `ConvertFrom-Json` turns them back. There is no `jq` step
because there is nothing to parse.

## Where the objects come from

**Some commands hand you objects. Most text does not.** The three cmdlets that
turn text into objects carry most of the load:

| | |
|---|---|
| `Import-Csv` | a CSV file, one object per row, properties from the header |
| `ConvertFrom-Json` | JSON, nested objects and all |
| `ConvertFrom-StringData` | a `key=value` file, into a hashtable |

And when the text is none of those — a log file, the output of a native program —
you build the objects yourself, which is what the one-question video does:

```sh
Get-Content access.log | ForEach-Object {
  $f = $_ -split " "
  [pscustomobject]@{ ip = $f[0]; path = $f[6]; status = [int]$f[8]; ms = [int]$f[-1] }
}
```

**That line is the honest price of the object pipeline.** Bash never has to write
it, because bash never stops working in text. PowerShell pays it once, at the
edge, and everything after is properties instead of column numbers.
