---
title: Providers — the registry is a drive, and so is the environment
version: 1
---

Lesson 1 section 09 said everything on Unix is a file. PowerShell's version of that idea
runs the other way: **everything that looks like a tree gets to be a drive**, and
the same four cmdlets work on all of them.

```
PS /home/ana/work/ps> Get-PSDrive | Format-Table -AutoSize
Name     Used (GB) Free (GB) Provider    Root   CurrentLocation
----     --------- --------- --------    ----   ---------------
/           225.77     26.20 FileSystem  /     home/ana/work/ps
Alias                        Alias
Env                          Environment
Function                     Function
Temp        225.77     26.20 FileSystem  /tmp/
Variable                     Variable
```

Six drives on this Linux machine, backed by five providers. **On Windows there
are more**, and two of them are the reason this idea exists: `HKLM:` and `HKCU:`,
the registry.

## The same cmdlets, on all of them

| | |
|---|---|
| `Get-ChildItem` | list what is in there |
| `Get-Item` / `Set-Item` | one thing |
| `New-Item` / `Remove-Item` | create, delete |
| `Get-Content` / `Set-Content` | what is inside it |
| `Test-Path` | is there something there |

```
PS /home/ana/work/ps> Get-ChildItem Env: | Where-Object Name -like "U*"
Name                           Value
----                           -----
USER                           ana
PS /home/ana/work/ps> $env:HOME
/home/ana
PS /home/ana/work/ps> Get-ChildItem Function: | Select-Object -First 3 Name
Name
----
cd..
cd\
cd~
```

`Env:` is the environment as a directory. `Function:` is every defined function
as a directory. `Variable:` is every variable. **You can `Get-ChildItem` your own
shell's state**, which is a genuinely different idea from anything in bash, where
the equivalents are `env`, `declare -F` and `declare -p` — three different
commands with three different output formats.

`$env:HOME` is the shorthand for `Get-Item Env:HOME | Select -Expand Value`, and
`$env:LEVEL = "debug"` sets one, exported to children, which is lesson 9 section 03's
`export` folded into the name.

## On Windows: the registry

This is the part that has no equivalent here and is why the idea pays for itself:

```sh
Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion | Select ProductName
New-Item -Path HKCU:\Software\MyApp
Set-ItemProperty -Path HKCU:\Software\MyApp -Name Level -Value debug
```

The registry is a tree of keys with values on them, so it is a drive, and reading
it uses the cmdlets you already know. On this machine it is not there:

```
PS /home/ana/work/ps> Get-ChildItem HKLM:\Software
Get-ChildItem: Cannot find drive. A drive with the name 'HKLM' does not exist.
```

**That is the error, unedited.** The registry provider ships in a Windows-only
module, so on Linux the drive simply does not exist. Those four lines above are
the only untested commands in this lesson and they are marked as such.

## Files

```
PS /home/ana/work/ps> Get-Content sales.csv -TotalCount 2
region,rep,quarter,units,revenue
north,ana,Q1,171,8721
PS /home/ana/work/ps> Get-Content sales.csv | Measure-Object -Line
Lines Words Characters Property
----- ----- ---------- --------
   33
```

**`Get-Content` emits one string per line**, not one big blob — which is why it
pipes into `Where-Object` and `ForEach-Object` the way `cat` pipes into `grep`.
`-Raw` gives you the whole file as a single string, and `-TotalCount` is `head`.

| bash | PowerShell |
|---|---|
| `cat f` | `Get-Content f` |
| `head -2 f` | `Get-Content f -TotalCount 2` |
| `tail -5 f` | `Get-Content f -Tail 5` |
| `tail -f f` | `Get-Content f -Wait` |
| `wc -l < f` | `(Get-Content f).Count` |
| `echo x > f` | `Set-Content f -Value x` |
| `echo x >> f` | `Add-Content f -Value x` |
| `test -e f` | `Test-Path f` |

**`Set-Content` and `>` are not the same**, and it is worth seeing once:

```
PS /home/ana/work/ps> Get-ChildItem > /tmp/redir.txt; Get-Content /tmp/redir.txt
    Directory: /home/ana/work/ps

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
-rw-r--r--        ana ana        09/15/2026 10:48       148233 access.log
-rwxr-xr-x        ana ana        09/15/2026 11:01          175 bigfiles.ps1
-rw-r--r--        ana ana        09/15/2026 10:48          788 sales.csv
PS /home/ana/work/ps> Get-ChildItem | Set-Content /tmp/setc.txt; Get-Content /tmp/setc.txt
/home/ana/work/ps/access.log
/home/ana/work/ps/bigfiles.ps1
/home/ana/work/ps/sales.csv
```

`>` wrote **the table a person would have read**, headers and all, because
redirection formats first. `Set-Content` wrote the values. Whichever you meant,
one of those files is going to disappoint whatever reads it next — and this is
section 07's rule arriving in a place you did not expect it.

## `Select-String` is `grep`

```
PS /home/ana/work/ps> Select-String -Path access.log -Pattern "500" | Select-Object -First 1 LineNumber, Line
LineNumber Line
---------- ----
        13 10.0.1.21 - - [14/Sep/2026:06:09:02 +0000] "POST /api/reports HTTP/1.1" 500 18487 "curl…
```

**And it returns objects**, with `LineNumber`, `Line`, `Filename` and `Matches`
on them — so the line number is a number you can use rather than something you
asked `grep -n` for and then had to `cut`.

| | |
|---|---|
| `-Pattern` | a regular expression by default. `-SimpleMatch` for literal text |
| `-CaseSensitive` | because, as ever, the default is not |
| `-Context 2,2` | `grep -C 2` |
| `-NotMatch` | `grep -v` |
| `-List` | stop at the first match per file — `grep -l` |
