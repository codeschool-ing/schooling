---
title: A Rosetta stone, and the four rules that produce it
version: 1
---

## Moving around and looking

| bash | PowerShell |
|---|---|
| `pwd` | `Get-Location` |
| `cd /etc` | `Set-Location /etc` |
| `ls` | `Get-ChildItem` |
| `ls -la` | `Get-ChildItem -Force` |
| `ls -R` | `Get-ChildItem -Recurse` |
| `find . -name '*.log'` | `Get-ChildItem -Recurse -Filter *.log` |
| `cat f` | `Get-Content f` |
| `head -5 f` | `Get-Content f -TotalCount 5` |
| `tail -f f` | `Get-Content f -Wait` |
| `cp a b` | `Copy-Item a b` |
| `mv a b` | `Move-Item a b` |
| `rm f` | `Remove-Item f` |
| `mkdir d` | `New-Item -ItemType Directory d` |
| `touch f` | `New-Item -ItemType File f` |
| `test -e f` | `Test-Path f` |
| `which cmd` | `Get-Command cmd` |
| `man cmd` | `Get-Help cmd -Full` |

## Text and data

| bash | PowerShell |
|---|---|
| `grep pat f` | `Select-String pat f` |
| `grep -v pat` | `Select-String pat -NotMatch` |
| `grep -c pat f` | `(Select-String pat f).Count` |
| `cut -d, -f2` | `Import-Csv f \| Select-Object col` |
| `sort` | `Sort-Object` |
| `sort -u` | `Sort-Object -Unique` |
| `sort \| uniq -c` | `Group-Object` |
| `wc -l` | `Measure-Object -Line` |
| `awk '{s+=$3} END{print s}'` | `Measure-Object col -Sum` |
| `sed 's/a/b/g'` | `$s -replace 'a','b'` |
| `tr a-z A-Z` | `$s.ToUpper()` |
| `paste -sd,` | `$arr -join ','` |
| `tr , '\n'` | `$s -split ','` |
| `xargs cmd` | `ForEach-Object { cmd $_ }` |
| `jq` | `ConvertFrom-Json`, and then properties |

## Processes and the system

| bash | PowerShell |
|---|---|
| `ps aux` | `Get-Process` |
| `kill PID` | `Stop-Process -Id PID` |
| `pkill -f name` | `Stop-Process -Name name` |
| `systemctl status x` | `Get-Service x` — Windows only |
| `systemctl restart x` | `Restart-Service x` — Windows only |
| `env` | `Get-ChildItem Env:` |
| `export X=1` | `$env:X = 1` |
| `echo $HOME` | `$env:HOME` |
| `date` | `Get-Date` |
| `sleep 5` | `Start-Sleep -Seconds 5` |
| `ssh host cmd` | `Invoke-Command -ComputerName host { cmd }` |

## Shell constructs

| bash | PowerShell |
|---|---|
| `$1 $2` | a `param()` block with names |
| `$@` | `$args`, or named parameters |
| `$?` (0 is good) | `$?` (`$true` is good), `$LASTEXITCODE` for programs |
| `set -u` | `Set-StrictMode -Version Latest` |
| `set -e` | `$ErrorActionPreference = 'Stop'` |
| `[ -f x ]` | `Test-Path x -PathType Leaf` |
| `[ "$a" = "$b" ]` | `$a -eq $b` |
| `[[ $a == pat* ]]` | `$a -like 'pat*'` |
| `[[ $a =~ re ]]` | `$a -match 're'` |
| `for f in *.log; do` | `foreach ($f in Get-ChildItem *.log) {` |
| `cmd \| while read l` | `cmd \| ForEach-Object { $_ }` |
| `func() { … }` | `function Verb-Noun { … }` |
| `local x` | the default. `$script:x` to escape it |
| `source f` | `. ./f`, or `Import-Module` |
| `2>&1` | `2>&1`, and `*>&1` for every stream |
| `> /dev/null` | `\| Out-Null` |
| `$(cmd)` | `$(cmd)` — the same |
| `$((1+2))` | `1+2` — arithmetic needs nothing |

## The four rules behind the table

Most of the table is derivable rather than memorable, from four things.

**One. The pipeline carries objects.** So there is no `awk`, no `cut` and no
`jq`: you take a property. And so `Format-*` is terminal, because it destroys the
objects to make a picture.

**Two. Commands are `Verb-Noun` and the verbs are approved.** So you do not
remember names — `Get-Command -Noun Service` finds them. And `Get-` is safe.

**Three. Parameters are named and typed.** So there are no single-letter flags to
memorise and no `getopts`: `-Recurse` says what it does, and `[int]$Threshold` in
a `param` block is four lines of bash validation.

**Four. Values have types.** So `Sort-Object` on a number sorts numerically —
provided it really is a number, which is the trap this lesson repeats three
times. Text read from a file is text until you cast it.

## And the four things bash does better

Symmetry is not honesty. There are things the text pipeline wins outright.

**Starting.** 0.4 seconds against 0.003. For anything a scheduler runs on a
timer, that is the whole argument.

**Brevity.** `ls | wc -l` against
`(Get-ChildItem | Measure-Object).Count`. At a prompt, typing matters.

**Everything speaks text.** Any program written in the last fifty years can be
part of a bash pipeline. A PowerShell pipeline is rich in the middle and has to
convert at both ends, and `ConvertFrom-Json` only helps when the other side
speaks JSON.

**It is already there.** Every Linux machine has bash; PowerShell is a download
and a decision. That is the same argument section 115 made about not reaching
outside the distribution, and it applies here.

**So the rule is not that one is better.** It is that on Windows the objects are
the only sane way to work, on Linux the text tools are, and the interesting skill
is knowing which machine you are on and not fighting it.
