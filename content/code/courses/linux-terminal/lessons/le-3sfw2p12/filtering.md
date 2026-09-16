---
title: `Where-Object`, and the comparison that quietly answers wrongly
version: 1
---

`Where-Object` keeps the objects for which a condition is true. It is `grep`
with a property instead of a pattern.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 30000 } | Select-Object rep, revenue
rep    revenue
---    -------
carla  37084
ana    43731
carla  30272
elena  34122
hugo   35541
carla  34417
felipe 41574
```

Two spellings, and both are everywhere:

```sh
Where-Object { $_.revenue -gt 30000 }      # the block form: any expression, $_ is the object
Where-Object revenue -gt 30000             # the comparison form: shorter, one property
```

## The operators are words

There are no `<` and `>` operators, because those are redirection — the same
collision bash has, resolved the other way.

| | |
|---|---|
| `-eq` `-ne` | equal, not equal |
| `-lt` `-le` `-gt` `-ge` | less, greater |
| `-like` `-notlike` | **glob** matching: `*` and `?` |
| `-match` `-notmatch` | **regular expression** matching |
| `-contains` `-in` | is this value in that collection |
| `-and` `-or` `-not` `!` | joining conditions |

**`-eq` is case-insensitive.** So are all of them:

```
PS /home/ana/work/ps> "ANA" -eq "ana"
True
PS /home/ana/work/ps> "ANA" -ceq "ana"
False
PS /home/ana/work/ps> "file.LOG" -like "*.log"
True
```

`-ceq`, `-clike`, `-cmatch` are the case-sensitive versions, with a leading `c`.
This is the opposite of every Unix tool, and it catches people both ways round —
a comparison that matches when you expected it not to, and a script ported to
bash that suddenly cares about capitals.

```sh
Where-Object { $_.Name -like '*.log' }        # glob, the same patterns as case in bash
Where-Object { $_.Name -match '^\d{4}-' }     # regex, the same syntax as lesson 125
```

`-match` also fills `$Matches` with the capture groups, the way `[[ =~ ]]` filled
`BASH_REMATCH` in lesson 9 section 08:

```
PS /home/ana/work/ps> "report-2026.log" -match "^(\w+)-(\d{4})"; $Matches[2]
True
2026
```

## The trap, measured

Here is the same file, the same threshold, and two answers:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { $_.revenue -gt 30000 } | Measure-Object | Select-Object Count
Count
-----
   16
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 30000 } | Measure-Object | Select-Object Count
Count
-----
    7
```

**Sixteen against seven, and nothing warned about the other nine.**

The previous section is why: `Import-Csv` produced strings, so `$_.revenue` is
the text `8721`. PowerShell's comparison operators **coerce the right-hand side
to the type of the left-hand side** — so `30000` became the string `"30000"`, and
the comparison was alphabetical.

```
PS /home/ana/work/ps> "9" -gt "30000"
True
PS /home/ana/work/ps> 9 -gt 30000
False
```

`"9"` sorts after `"3"`, so as text nine is greater than thirty thousand. It is
exactly the `[ "10" \> "9" ]` problem from lesson 9 section 08, arriving from the other
direction — there the shell made you choose an operator, here the operator is the
same and the *type* decides.

**Cast at the boundary.** `[int]`, `[double]`, `[datetime]`, on the line where
text becomes data:

```sh
Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 30000 }

Import-Csv sales.csv | ForEach-Object {
  $_.revenue = [int]$_.revenue      # or fix it once, and stop thinking about it
  $_
}
```

The second is better in anything longer than a one-liner, and it is what
`[pscustomobject]@{ status = [int]$f[8] }` in the one-question video is doing.

## Which side is the collection

```sh
$allowed -contains $name      # the collection is on the LEFT
$name -in $allowed            # the collection is on the RIGHT
```

Both ask the same question and they are mirror images. `-in` reads better and is
newer; `-contains` is in every old script. Getting them the wrong way round is
the usual shape of a PowerShell mistake:

```
PS /home/ana/work/ps> $allowed = "web01","web02"; $allowed -contains "web01"; "web01" -in $allowed
True
True
PS /home/ana/work/ps> "web01" -contains $allowed
False
```

**`False`, not an error.** A single string is a collection of one, and it does
not contain a two-element array, so the answer is perfectly correct and
perfectly useless.

## Filtering left, when you can

```sh
Get-ChildItem -Filter '*.log'                        # the provider does it
Get-ChildItem | Where-Object { $_.Name -like '*.log' }   # PowerShell does it
```

Both give the same answer. **`-Filter` is handled by the thing supplying the
objects** — the filesystem, the directory service, the remote machine — so fewer
objects are ever built. `Where-Object` builds all of them and discards most.

On two files it does not matter. On a directory server with forty thousand
accounts, or across a network, it is the difference between a second and a
minute. **Filter as far left as the command will let you**, which is lesson 8's
"reduce before you decide" in a different accent.
