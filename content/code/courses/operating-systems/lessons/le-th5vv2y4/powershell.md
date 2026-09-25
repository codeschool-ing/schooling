---
title: The same walk in PowerShell
version: 1
---

PowerShell's commands are called **cmdlets**, and every one is named **Verb-Noun**: `Get-Location`,
`Set-Location`, `Get-ChildItem`. It is longer to type and far easier to guess. Here is the same walk,
in PowerShell 7 on the same server:

```
PS /home/ana> Get-Location

Path
----
/home/ana

PS /home/ana> Set-Location office
PS /home/ana/office> Get-ChildItem

    Directory: /home/ana/office

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
drwxrwxr-x        ana ana        09/01/2026 09:00         4096 clients
drwxrwxr-x        ana ana        09/01/2026 09:00         4096 invoices 2026
drwxrwxr-x        ana ana        09/01/2026 09:00         4096 scans
-rw-rw-r--        ana ana        09/01/2026 09:00           25 notes.txt

PS /home/ana/office> Set-Location 'invoices 2026'
PS /home/ana/office/invoices 2026> Get-Location

Path
----
/home/ana/office/invoices 2026

PS /home/ana/office/invoices 2026> Set-Location ..
PS /home/ana/office> cd clients
PS /home/ana/office/clients> pwd

Path
----
/home/ana/office/clients
```

- **`Get-Location`** is `pwd`, and answers with a small table, because what it returns is an object
  with a `Path` property. Section 06 comes back to that.
- **`Set-Location`** is `cd`. Quotes work the same way around `'invoices 2026'`.
- **`Get-ChildItem`** is `ls`, and on Linux it shows the same permission string in a column called
  `UnixMode`.
- The last two lines typed **`cd`** and **`pwd`**, and they worked, because PowerShell defines short
  **aliases** for its cmdlets.

## Aliases, and why they differ between systems

```
PS /home/ana> Get-Alias cd, pwd, dir, gci

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Alias           cd -> Set-Location
Alias           pwd -> Get-Location
Alias           dir -> Get-ChildItem
Alias           gci -> Get-ChildItem

PS /home/ana> Get-Command ls

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Application     ls                                                 0.0.0.0    /usr/bin/ls
```

`cd`, `pwd`, `dir` and `gci` are aliases on every system. **`ls` is not, here**: on Linux, PowerShell
leaves `ls` to the real `/usr/bin/ls` so as not to hide it. **On Windows, `ls` is an alias for
`Get-ChildItem`**, which is why `ls` "works" in PowerShell on Windows and then does not accept `-l`:

```sh
PS C:\Users\ana> Set-Location Documents
PS C:\Users\ana\Documents> Get-ChildItem
PS C:\Users\ana\Documents> Get-Alias ls        # on Windows: ls -> Get-ChildItem
PS C:\Users\ana\Documents> $env:USERPROFILE
```

**None of that was run for this lesson.** The lesson from it is general: an alias makes a command look
familiar, and the options you know from the original do not come with it. In a script, write the full
cmdlet name.
