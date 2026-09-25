---
title: What the prompt tells you
version: 1
---

The line the cursor sits on is the **prompt**, and it is information, not decoration. Three commands
confirm what the default Ubuntu prompt already says:

```
ana@server:~$ whoami
ana
ana@server:~$ hostname
server
ana@server:~$ pwd
/home/ana
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four prompts taken apart. ana@server:~/office$ says who you are, ana; which machine, server; where you are, ~/office; and the dollar sign means an ordinary user. root@server:/home/ana# is the administrator, root, and the hash sign says be careful. PS /home/ana/office&gt; is PowerShell, followed by where you are. C:\\Users\\ana&gt; is cmd.exe on Windows, showing where you are.\"><defs><marker id=\"pr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana@server:~/office$</text><text x=\"300\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">ana</text><text x=\"440\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">who you are</text><text x=\"300\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">server</text><text x=\"440\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">which machine</text><text x=\"300\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">~/office</text><text x=\"440\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where you are</text><text x=\"300\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">$</text><text x=\"440\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">an ordinary user</text><rect x=\"20\" y=\"96\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">root@server:/home/ana#</text><text x=\"300\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">root</text><text x=\"440\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the administrator</text><text x=\"300\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">#</text><text x=\"440\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">careful: root</text><rect x=\"20\" y=\"160\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PS /home/ana/office&gt;</text><text x=\"300\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">PS</text><text x=\"440\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">PowerShell</text><text x=\"300\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">/home/ana/office</text><text x=\"440\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where you are</text><rect x=\"20\" y=\"224\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C:\\Users\\ana&gt;</text><text x=\"300\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C:\\Users\\ana</text><text x=\"440\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cmd.exe on Windows: where you are</text></svg>", "caption": "Read the prompt before typing. It answers the three questions that decide whether a command is safe: who, on which machine, and where."}
```

The last character matters most. **`$` is an ordinary user; `#` is root**, the administrator of
lesson 3, for whom nothing is refused. `sudo -s` opens a whole shell as root, and the prompt changes
at once:

```
ana@server:~$ sudo -s
root@server:/home/ana# whoami

root
root@server:/home/ana# exit

exit
```

**A `#` prompt means every command goes straight through**, with no password and no second chance. Do
what needs root, and `exit` as soon as it is done. Lesson 10 explains why working as an ordinary user
and borrowing root per command, as `sudo` does, is the safer habit.

## The other prompts

The same three facts appear, differently arranged, on the other systems:

```sh
C:\Users\ana> cd Documents
C:\Users\ana\Documents> dir
C:\Users\ana\Documents> cd ..
C:\Users\ana> echo %USERPROFILE%
```

```sh
ana@Anas-MacBook-Air ~ % cd Documents
ana@Anas-MacBook-Air Documents % ls -l
ana@Anas-MacBook-Air Documents % echo $SHELL      # /bin/zsh
```

**Neither was run for this lesson.** The first is **Command Prompt**, `cmd.exe`, the Windows shell
that descends from MS-DOS. It shows only the path. The second is macOS's **zsh**, which has
been the Mac's default shell since 2019: user, machine name, the current folder's name, and `%` where
bash shows `$`.
