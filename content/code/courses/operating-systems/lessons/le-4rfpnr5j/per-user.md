---
title: Each person's own settings
version: 1
---

`/etc` is the machine's. Each person's own settings live **in their home folder**, in files whose names
start with a dot, which is why lesson 8's `ls -a` mattered:

```
ana@server:~$ ls -A ~
.bash_logout
.bashrc
.cache
.local
.profile
.sudo_as_admin_successful
downloads
office
upgrade.log
work
ana@server:~$ grep -c . ~/.bashrc
96
ana@server:~$ grep -n 'HISTSIZE' ~/.bashrc
18:# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
19:HISTSIZE=1000
PS /home/ana> $PROFILE
/home/ana/.config/powershell/Microsoft.PowerShell_profile.ps1
```

- **`.bashrc`** is read by every new bash, and holds ana's shell settings: 96 non-empty lines here,
  among them `HISTSIZE=1000`, how many commands lesson 8's `history` remembers.
- **`.profile`** is read once at login.
- **`.config`** and **`.local`** hold newer programs' settings and data, one folder per program. The
  `.config` folder does not exist yet in this home; the first program that needs it creates it.
- **`$PROFILE`** is PowerShell's own `.bashrc`: the path it would read, under `~/.config/powershell`,
  even though no such file has been written.

A user setting overrides the machine's for that person only, which is what makes it safe: a broken
`.bashrc` breaks one account, and `/etc` is untouched. **To reset a program for one person, move its
dot-folder aside**, never delete it straight away; it is lesson 12's copy-first rule again.
