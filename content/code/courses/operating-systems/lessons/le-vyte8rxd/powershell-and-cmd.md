---
title: The same four jobs in PowerShell and the Command Prompt
version: 1
---

PowerShell's cmdlets say what they do, lesson 8's Verb-Noun:

```
PS /home/ana/work> New-Item -ItemType Directory -Path archive

    Directory: /home/ana/work

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
drwxrwxr-x        ana ana        09/25/2026 11:15         4096 archive

PS /home/ana/work> Set-Content -Path archive/readme.txt -Value 'old invoices, kept for five years'
PS /home/ana/work> Add-Content -Path archive/readme.txt -Value 'ask the accountant before deleting'
PS /home/ana/work> Get-Content archive/readme.txt
old invoices, kept for five years
ask the accountant before deleting
PS /home/ana/work> Get-Content backup.log -Tail 2
2026-09-24 09:58 backup ok
2026-09-24 09:59 backup ok
PS /home/ana/work> Copy-Item clients.csv archive/
PS /home/ana/work> Remove-Item archive -Recurse -WhatIf
What if: Performing the operation "Remove Directory" on target "/home/ana/work/archive".
PS /home/ana/work> Get-ChildItem archive -Name
clients.csv
readme.txt
```

| job | bash | PowerShell | Command Prompt |
|---|---|---|---|
| make a folder | `mkdir -p` | `New-Item -ItemType Directory` | `md` |
| write a file | `echo … >` | `Set-Content` | `echo … >` |
| add to a file | `echo … >>` | `Add-Content` | `echo … >>` |
| read a file | `cat`, `tail` | `Get-Content`, `-Tail` | `type` |
| copy | `cp`, `cp -r` | `Copy-Item`, `-Recurse` | `copy`, `xcopy` |
| move or rename | `mv` | `Move-Item`, `Rename-Item` | `move`, `ren` |
| delete | `rm`, `rm -r` | `Remove-Item`, `-Recurse` | `del`, `rd /s` |

The Command Prompt column was not run for this lesson. `>` and `>>` mean the same in all three shells,
with the same danger.

## `-WhatIf`

The most useful switch in PowerShell for this lesson is **`-WhatIf`**. `Remove-Item archive -Recurse
-WhatIf` **described** what it would delete and deleted nothing: the last command still found both
files in `archive`. It is section 05's "look first", built into the command, and most cmdlets that
change something accept it. **`-Confirm`** is the equivalent of `rm -i`.

`Remove-Item` on a folder that has something in it asks for confirmation unless `-Recurse` is given,
a guard `rm -r` does not have.
