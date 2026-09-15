---
title: Functions that check their own arguments
version: 1
---

```
PS /home/ana/work/ps> function Get-Doubled { param([int]$Number) $Number * 2 }
PS /home/ana/work/ps> Get-Doubled -Number 21
42
PS /home/ana/work/ps> Get-Doubled 21
42
```

`function Verb-Noun { param(…) … }`. The name follows the same convention as a
cmdlet, because a function **is** one as far as everything else is concerned —
`Get-Command` finds it, `Get-Help` documents it, and it can be piped to.

## `param` is the difference

Section 150's bash functions took `$1` and `$2` and checked nothing. PowerShell's
`param` block declares names, types and rules, and the shell enforces them
**before your code runs**:

```
PS /home/ana/work/ps> Get-Doubled -Number "twelve"
Get-Doubled: Cannot process argument transformation on parameter 'Number'. Cannot convert value "twelve" to type "System.Int32". Error: "The input string 'twelve' was not in a correct format."
```

Nothing inside the function had to test anything. Compare with lesson 9's
`logreport.sh`, which spends four lines checking that `-t` is a number.

The declaration grows as far as you need:

```sh
function Get-Report {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [ValidateRange(1, 60000)]
    [int]$ThresholdMs = 1000,

    [ValidateSet('Table', 'Json', 'Csv')]
    [string]$As = 'Table',

    [switch]$Quiet
  )
  …
}
```

| | |
|---|---|
| `[Parameter(Mandatory)]` | PowerShell **prompts** for it if it is missing |
| `[ValidateRange]` `[ValidateSet]` `[ValidatePattern]` | rejected before the body runs |
| `= 1000` | a default |
| `[switch]` | a flag. `$Quiet.IsPresent`, or just `if ($Quiet)` |
| `[CmdletBinding()]` | see below |

```
PS /home/ana/work/ps> function Pick { param([ValidateSet("Table","Json")]$As) "as $As" }
PS /home/ana/work/ps> Pick -As Json
as Json
PS /home/ana/work/ps> Pick -As Xml
Pick: Cannot validate argument on parameter 'As'. The argument "Xml" does not belong to the set "Table,Json" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again.
```

The message names the parameter, the bad value and the allowed set, and none of
that was written by the function's author. `[ValidateSet]` also drives tab
completion for the caller.

**`[CmdletBinding()]` is one line and it gives you five things**: `-Verbose`,
`-Debug`, `-ErrorAction`, `-WarningAction` and `-WhatIf`/`-Confirm` support, all
handled by PowerShell. `Write-Verbose "…"` in the body then prints only when the
caller passes `-Verbose`. There is no bash equivalent short of writing it.

## Returning values

```
PS /home/ana/work/ps> function Get-Two { "first"; "second" }
PS /home/ana/work/ps> $r = Get-Two; $r.Count; $r[1]
2
second
```

**Every expression that is not consumed becomes output.** There is no `return`
needed, and `return $x` means "emit `$x` and stop here" rather than "this is the
value" — a `return` is not what produces the result.

This is the same as bash's "a function returns data on standard output" from
section 150, with one big difference: what comes back is **objects**, not text.
`$r` is an array of two strings, `$r[1]` is the second one, and nothing was
parsed.

And it is the same trap. A stray `Write-Output` or an uncaptured expression joins
the return value:

```sh
function Get-Size {
  Write-Host "measuring…"          # fine: bypasses the pipeline
  Write-Output "measuring…"        # NOT fine: this is now part of the result
  (Get-Item $Path).Length
}
```

**`Write-Host` for a person, `Write-Verbose` for a person who asked, and nothing
else on the output stream but the answer.**

## Taking pipeline input

This is what makes a function feel like a cmdlet:

```
PS /home/ana/work/ps> function Get-Big { param([Parameter(ValueFromPipeline)]$Item) process { if ($Item.Length -gt 1000) { $Item.Name } } }
PS /home/ana/work/ps> Get-ChildItem | Get-Big
access.log
```

Two pieces:

| | |
|---|---|
| `[Parameter(ValueFromPipeline)]` | this parameter is filled from the pipeline |
| `process { }` | **runs once per object.** Without it, only the last one arrives |

There are three blocks: `begin` runs once before, `process` once per object,
`end` once after. A function with no blocks at all is treated as one big `end`,
and here is what that costs:

```
PS /home/ana/work/ps> function No-Process { param([Parameter(ValueFromPipeline)]$Item) if ($Item) { "got $($Item.Name)" } }
PS /home/ana/work/ps> Get-ChildItem | No-Process
got sales.csv
PS /home/ana/work/ps> function With-Process { param([Parameter(ValueFromPipeline)]$Item) process { "got $($Item.Name)" } }
PS /home/ana/work/ps> Get-ChildItem | With-Process
got access.log
got sales.csv
```

**Two files went in and the first one said one.** The body ran once, at the end,
with `$Item` holding whatever arrived last. No error — the usual shape.

`[Parameter(ValueFromPipelineByPropertyName)]` is the other one: it fills
`$Path` from a `.Path` property on whatever came down the pipe, which is how
cmdlets chain without anybody writing glue.

## Scope

Variables are visible to functions **called from** where they are defined, and
assignment inside a function creates a local one — the opposite default from
bash, where section 150 had to say `local` on every line.

```
PS /home/ana/work/ps> $x = 1; function Set-It { $x = 2 }; Set-It; "x is $x"
x is 1
PS /home/ana/work/ps> $x = 1; function Set-It2 { $script:x = 2 }; Set-It2; "x is $x"
x is 2
```

`$script:`, `$global:` and `$local:` are explicit scopes. **Needing one is
usually a sign the function should return a value instead.**

## Where functions live

A `.ps1` file is a script; a `.psm1` file is a module. `Import-Module ./tools.psm1`
brings its functions in — the `source` of section 139, with a manifest and
version numbers attached.

**A script file does not need a shebang on Windows** and does need one on Linux —
`#!/usr/bin/env pwsh`, exactly as section 139 described — and then it is an
ordinary executable file, from an ordinary bash prompt:

```
ana@vm:~/work/ps$ cat bigfiles.ps1
#!/usr/bin/env pwsh
param([Parameter(Mandatory)][string]$Path, [int]$MinBytes = 1000)
Get-ChildItem $Path |
  Where-Object Length -gt $MinBytes |
  Select-Object Name, Length
ana@vm:~/work/ps$ ./bigfiles.ps1 -Path .

Name       Length
----       ------
access.log 148233
```

Note that `param()` works at the top of a script file and not just in a function,
and that the parameters are named the PowerShell way even though bash launched
it. A script's `param` block must be the **first statement in the file**, after
the shebang and any comments.

What a `.ps1` needs on Windows and not here is permission:
`Set-ExecutionPolicy RemoteSigned` for the user, because by default a freshly
written script will not run at all. That is a Windows-only setting and there is
nothing on this machine to demonstrate it on.
