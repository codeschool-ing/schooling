---
title: Environment variables: settings every program can read
version: 1
---

Every process carries a set of named values, **environment variables**, which it passes on to every
program it starts. They answer questions like *where is this person's home* and *where are the
programs*.

```
ana@server:~$ echo $HOME
/home/ana
ana@server:~$ echo $PATH | tr ":" "\n" | head -4
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
ana@server:~$ printenv USER SHELL
ana
/bin/bash
PS /home/ana> $env:HOME
/home/ana
PS /home/ana> $env:USER
ana
```

- **`$HOME`** is the home folder and `$USER` the account name. `echo` prints them; `printenv` does
  too, without the `$`.
- **`$PATH`** is the list of folders searched, in order, when you type a command's name. It is why `ls`
  runs `/usr/bin/ls` without anybody typing the folder, and why a program installed somewhere not on the
  list is "command not found" although it is on the disk. On Linux and macOS the folders are separated by
  `:`.
- PowerShell reads the same variables as **`$env:HOME`**, `$env:USER`, the `env:` drive.

On Windows the names and the separator change:

```sh
echo %USERPROFILE%
echo %PATH%
```

```sh
$env:USERPROFILE                  # C:\Users\ana
$env:Path -split ';'              # one folder per line
```

**`%NAME%`** in the Command Prompt, `$env:NAME` in PowerShell, and the folders in `PATH` separated
by `;`, because `:` already appears in every Windows path after the drive letter. The home folder is
**`USERPROFILE`**, not `HOME`.
