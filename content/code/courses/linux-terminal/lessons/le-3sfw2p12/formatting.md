---
title: `Format-*` is the end of the pipeline, and never the middle
version: 1
---

Every table you have seen in this lesson was produced by a formatter that
PowerShell ran automatically at the end, choosing a table or a list depending on
how many properties there were.

You can ask for one explicitly:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Select-Object -First 2 | Format-Table -AutoSize
region rep   quarter units revenue
------ ---   ------- ----- -------
north  ana   Q1      171   8721
north  bruno Q1      49    4116
PS /home/ana/work/ps> Import-Csv sales.csv | Select-Object -First 1 | Format-List
region  : north
rep     : ana
quarter : Q1
units   : 171
revenue : 8721
```

| | |
|---|---|
| `Format-Table` | columns. `-AutoSize` fits them to the content |
| `Format-List` | one property per line. What you want when there are many |
| `Format-Wide` | one property, in columns, like `ls` |
| `Out-Host -Paging` | a pager, like `less` |

**`Format-Table -AutoSize` has to buffer everything** to work out the widths, so
it stops the pipeline streaming — the same trade as `Sort-Object`.

## The rule

**Nothing comes after a `Format-*` except output.**

```
PS /home/ana/work/ps> Import-Csv sales.csv | Format-Table | Where-Object { $_.region -eq "north" } | Measure-Object | Select Count
Count
-----
    0
```

Eight rows have `region` of `north` and the answer is zero. Ask what
`Format-Table` actually emitted:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Format-Table | Get-Member | Select-Object -First 3 TypeName, Name
TypeName                                                      Name
--------                                                      ----
Microsoft.PowerShell.Commands.Internal.Format.FormatStartData Equals
Microsoft.PowerShell.Commands.Internal.Format.FormatStartData GetHashCode
Microsoft.PowerShell.Commands.Internal.Format.FormatStartData GetType
```

**`Format-Table` did not emit sales records. It emitted formatting
instructions** — `FormatStartData`, then a row per line, then a `FormatEndData` —
which are objects describing a table rather than the data in it. `Where-Object`
dutifully looked for a `region` property on them, found none, and kept nothing.

This is the single most common PowerShell mistake after the string comparison,
and it has the same shape: **no error, a clean empty answer.**

The fix is the order. Filter, sort and select first; format last:

```sh
Import-Csv sales.csv | Where-Object region -eq north | Format-Table   # right
Import-Csv sales.csv | Format-Table | Where-Object region -eq north   # wrong
```

## When you want text, ask for text

`Format-*` is for a human reading a screen. For anything else there is a cmdlet
that produces data:

| | |
|---|---|
| `ConvertTo-Json` | JSON. `-Depth n`, because the default is 2 and it truncates |
| `ConvertTo-Csv` `Export-Csv` | CSV, to the pipeline or to a file |
| `Out-String` | the rendering, as a string, for when you really do want the text |
| `Out-File` `Set-Content` | to a file |
| `Out-Null` | to nowhere. The `> /dev/null` of section 121 |

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

**That is the boundary back out to the Unix world.** A PowerShell pipeline that
has to hand its results to something else converts them, and JSON is what
everything on the other side can read.

The `-Depth` on `ConvertTo-Json` is worth knowing before it bites:

```
PS /home/ana/work/ps> @{a=@{b=@{c=@{d=1}}}} | ConvertTo-Json
WARNING: Resulting JSON is truncated as serialization has exceeded the set depth of 2.
{
  "a": {
    "b": {
      "c": "System.Collections.Hashtable"
    }
  }
}
```

**Two levels by default**, and anything deeper becomes the type name as a
string — `"System.Collections.Hashtable"` where an object should be. It warns, at
least on this version, and the warning goes to the warning stream rather than
into the JSON. `-Depth 10` is the habit to form.

`Export-Csv -NoTypeInformation` was needed in older versions to stop a `#TYPE`
comment being written as the first line; in PowerShell 6 and later it is the
default and the switch is accepted and ignored.

## `Write-Host` is not output

```sh
Write-Output "this goes down the pipeline"
Write-Host   "this goes straight to the screen"
```

**`Write-Output` emits an object.** It is what a function returns, it can be
captured, piped and redirected — the standard output of section 120.

**`Write-Host` writes to the host application**, bypassing the pipeline
altogether:

```
PS /home/ana/work/ps> $a = Write-Output "captured"; "a is [$a]"
a is [captured]
PS /home/ana/work/ps> $b = Write-Host "not captured"; "b is [$b]"
not captured
b is []
PS /home/ana/work/ps> Write-Host "to file?" > /tmp/ps-h.txt; (Get-Content /tmp/ps-h.txt).Count
to file?
0
```

It went to the screen both times and into neither the variable nor the file. It
is for a progress message to a person, and using it to return a value is the
mistake that makes a function look like it returns nothing.

There are also `Write-Error`, `Write-Warning`, `Write-Verbose` and
`Write-Debug` — separate streams, the way standard error is separate, each with
its own switch to turn it on. That is the closest thing PowerShell has to
`>&2`, and it is better organised than the shell's two-stream arrangement.
