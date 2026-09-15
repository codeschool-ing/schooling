---
title: Verb-Noun, and how to find a command you do not know
version: 1
---

Unix command names are archaeology: `cat` concatenates, `awk` is three people's
initials, `less` is a joke about `more`. You learn them one at a time and there
is no pattern.

**Every PowerShell command is `Verb-Noun`.** `Get-ChildItem`, `Set-Location`,
`Stop-Process`, `Import-Csv`. The verb says what is being done, the noun says
what it is done to, and both come from a controlled list.

```
PS /home/ana/work/ps> Get-Verb | Select-Object -First 8 Verb, Group
Verb   Group
----   -----
Add    Common
Clear  Common
Close  Common
Copy   Common
Enter  Common
Exit   Common
Find   Common
Format Common
```

**The verbs are approved**, in groups — Common, Data, Lifecycle, Security and a
few more — and a module that invents one gets a warning when it loads. That
sounds bureaucratic and it is what makes the next section work.

| | |
|---|---|
| `Get` | read something and return it. Never changes anything |
| `Set` | overwrite it |
| `New` | create one that did not exist |
| `Remove` | delete |
| `Add` | append to something that exists |
| `Start` `Stop` | lifecycle |
| `Test` | return true or false |

**`Get-` is safe and `Set-` is not**, which is a real convention rather than a
hope: a cmdlet named `Get-` that changed something would fail review in the
module it shipped in.

## Finding a command

You do not memorise the names. You ask.

```
PS /home/ana/work/ps> Get-Command -Verb Get -Noun Child*
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Cmdlet          Get-ChildItem                                      7.0.0.0    Microsoft.PowerShell…
```

The more useful direction is by noun, because it shows you everything you can do
to a kind of thing:

```
PS /home/ana/work/ps> Get-Command -Noun Object | Select-Object Name
Name
----
Compare-Object
ForEach-Object
Group-Object
Measure-Object
New-Object
Select-Object
Sort-Object
Tee-Object
Where-Object
```

**That is the entire toolkit of this lesson, discovered rather than remembered.**
`Get-Command -Noun Service` on a Windows machine does the same for services;
`-Noun Process` for processes.

## `Get-Help`

```
PS /home/ana/work/ps> Get-Help Get-ChildItem -Parameter Recurse
-Recurse

    Required?                    false
    Position?                    Named
    Accept pipeline input?       false
    Parameter set name           (All)
    Aliases                      s
    Dynamic?                     false
    Accept wildcard characters?  false
```

| | |
|---|---|
| `Get-Help X` | the summary |
| `Get-Help X -Examples` | **the one to use.** Written by whoever wrote the cmdlet |
| `Get-Help X -Parameter Y` | one parameter, as above |
| `Get-Help X -Full` | everything |
| `Get-Help X -Online` | opens the documentation page in a browser |

`Get-Help` reads help files that ship separately from the cmdlets;
`Update-Help` downloads them, and a fresh machine will tell you the help is
minimal until you have run it.

## Parameters are named, and can be shortened

```
PS /home/ana/work/ps> Get-ChildItem -Pa /etc -Fi "host*" | Select-Object Name
Name
----
host.conf
hostname
hosts
hosts.allow
hosts.deny
```

**A parameter name can be abbreviated to any prefix that is not ambiguous** —
`-Pa` for `-Path`, `-Fi` for `-Filter`. It is a convenience at a prompt and a
liability in a file: a later version of the cmdlet that adds another `Pa…`
parameter turns your `-Pa` into an error in a script you have not touched. Write
them out in scripts.

`-Path` is also positional, so `Get-ChildItem /etc` works with no parameter name
at all.

Switch parameters take no value: `-Recurse` is on by being present. And there is
a spelling for turning one off explicitly, which matters when the value comes
from a variable:

```
PS /home/ana/work/ps> Get-ChildItem /etc -Filter "host*" -Recurse:$false | Select-Object Name
Name
----
host.conf
hostname
hosts
hosts.allow
hosts.deny
```

## Aliases, and a cross-platform surprise

```
PS /home/ana/work/ps> Get-Alias ls, dir, cat, ps, cd | Format-Table -AutoSize
Get-Alias: This command cannot find a matching alias because an alias with the name 'ls' does not exist.

CommandType Name                 Version Source
----------- ----                 ------- ------
Alias       dir -> Get-ChildItem
Get-Alias: This command cannot find a matching alias because an alias with the name 'cat' does not exist.
Get-Alias: This command cannot find a matching alias because an alias with the name 'ps' does not exist.
Alias       cd -> Set-Location
```

`dir` and `cd` are aliases here. **`ls`, `cat` and `ps` are not** — and on
Windows PowerShell they are, pointing at `Get-ChildItem`, `Get-Content` and
`Get-Process`.

The reason is obvious once you see it: on Linux those are real programs that a
person typing `ls` means, so PowerShell removes the aliases and lets the real
ones through. On Windows there is no `/bin/ls` to collide with.

**Which is why a script that says `ls` does something different on the two
platforms**, and why aliases belong at a prompt and never in a file. In a script,
write `Get-ChildItem`.

A few you will see anyway, because everybody types them:

```
PS /home/ana/work/ps> Get-Alias gci, "?", "%", select, sort, ft, fl | Format-Table -AutoSize
CommandType Name                    Version Source
----------- ----                    ------- ------
Alias       gci -> Get-ChildItem
Alias       ? -> Where-Object
Alias       % -> ForEach-Object
Alias       h -> Get-History
Alias       r -> Invoke-History
Alias       % -> ForEach-Object
Alias       select -> Select-Object
Get-Alias: This command cannot find a matching alias because an alias with the name 'sort' does not exist.
Alias       ft -> Format-Table
Alias       fl -> Format-List
```

Two things in that output were not asked for. **`sort` is missing** — same reason
as `ls`: `/usr/bin/sort` exists here, so the alias is not created, and on Windows
it is. And `h`, `r` and a second `%` appeared because **`Get-Alias` treats its
argument as a wildcard**, and `?` matches any single character — which is a
small, honest demonstration that `?` and `*` are patterns nearly everywhere in
PowerShell.

`Get-Alias` with no arguments lists every one of them.
