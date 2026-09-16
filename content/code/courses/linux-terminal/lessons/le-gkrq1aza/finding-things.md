---
title: Finding a package, and finding what a file came from
version: 1
---

Four questions, and each has one command. They are different questions and people use the wrong
tool for three of them.

| | |
|---|---|
| "what is this package called?" | `apt search` |
| "what is in this package?" | `apt show`, `dpkg -L` |
| "what put this file here?" | `dpkg -S` |
| "which package would give me this file?" | `apt-file search` |

The third and fourth look the same and are opposites: **`dpkg -S` asks the database of what is
installed; `apt-file` asks the repositories about what is not.**

## Searching by name and by description

```
root@vm:~# apt search "^ripgrep$" 2>/dev/null
Sorting... Done
Full Text Search... Done
ripgrep/noble,now 14.1.0-1 amd64 [installed]
  Recursively searches directories for a regex pattern
```

`apt search` matches the **name and the description**, which is why it is good at "something that
does X" and bad at "the thing called X". The pattern is a regular expression, so `^ripgrep$` pins
it to exactly that name — without the anchors you get everything whose description mentions it.

Read the line it printed: `ripgrep/noble,now 14.1.0-1 amd64 [installed]`. The suite it comes from,
the version, the architecture, and `[installed]` — four facts in one line, and the last one is the
one people miss and reinstall over.

`apt-cache search` is the older spelling and it prints a plainer list:

```
root@vm:~# apt-cache search json | head -5
libapache2-mod-php8.0 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.1 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.2 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.3 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.4 - server-side, HTML-embedded scripting language (Apache 2 module)
```

Five modules for PHP from a search for `json`, because each of their descriptions mentions it
somewhere. **That is the failure mode of description search**, and it is why `^name$` is worth
typing.

## What is installed

```
root@vm:~# apt list --installed 2>/dev/null | head -6
Listing...
acl/noble-updates,now 2.3.2-1build1.1 amd64 [installed]
adduser/noble,now 3.137ubuntu1 all [installed]
adwaita-icon-theme/noble,now 46.0-1 all [installed]
age/noble-updates,noble-security,now 1.1.1-1ubuntu0.24.04.3 amd64 [installed]
apt-transport-https/noble-updates,now 2.8.3 all [installed]
```

Note `age`'s line: `noble-updates,noble-security,now`. **That package is available from two suites**
and the security one is why it matters — a package listing `noble-security` has had a security
update published for it, which is a different thing from a normal version bump.

`dpkg -l` is the other way to ask, and it is the one whose output is a table with a status column:

```
root@vm:~# dpkg -l cowsay
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-=================================
ii  cowsay         3.03+dfsg2-8 all          configurable talking cow
```

**Those first three lines are a legend, printed every time, and they are the key to the `ii`.** The
first letter is what you want, the second is what is true, the third is whether there is an error.
`ii` is "wanted installed, is installed, no error" — and section 08 shows an `rc` and section 07
shows an `iU`.

## What a package put on the disk

```
root@vm:~# dpkg -L cowsay | head -8
/.
/usr
/usr/games
/usr/games/cowsay
/usr/share
/usr/share/cowsay
/usr/share/cowsay/cows
/usr/share/cowsay/cows/apt.cow
```

Every path the package owns, directories included. **This is how you find where something actually
installed itself** when it is not on your `PATH` — and `cowsay` is a real example, because it goes
in `/usr/games`:

```
root@vm:~# which cowsay
/usr/games/cowsay
```

`dpkg -L thing | grep bin` is the shortcut when you only want the commands, and
`dpkg -L thing | grep etc` when you want to know what it will configure.

## What put this file here

```
root@vm:~# dpkg -S /usr/games/cowsay
cowsay: /usr/games/cowsay
root@vm:~# dpkg -S /usr/bin/ls
coreutils: /usr/bin/ls
root@vm:~# dpkg -S /usr/bin/zipinfo
unzip: /usr/bin/zipinfo
```

**This is the one to have in your fingers.** A strange binary, a config file you did not write, a
library in a version that surprises you — `dpkg -S` names the package in an instant, because it is
a database lookup rather than a search.

And the answer that teaches the most is the one where there is no answer:

```
root@vm:~# dpkg -S /usr/local/bin/python3
dpkg-query: no path found matching pattern /usr/local/bin/python3
```

**Nothing owns it.** Lesson 3 said `/usr/local` is for software you installed yourself, and this is
that sentence with teeth: a file there was not packaged, will not be upgraded, will not be removed,
and will not be mentioned by anything in this lesson. It is yours. Section 13 is about how those
get there.

`rpm -qf` is the same question on the other family, and section 10 uses it.

## The file you do not have yet

`dpkg -S` cannot answer "which package would give me `pdftotext`", because the package is not
installed and its file list is not on your machine. `apt-file` downloads the file lists so it can:

```
root@vm:~# apt-file search bin/pdftotext
poppler-utils: /usr/bin/pdftotext         
root@vm:~# which pdftotext; echo "exit: $?"
exit: 1
```

**The file is not on this machine and the question was still answered.** `which` finds nothing;
`apt-file` names the package that would provide it. That is the command for "bash says command not
found and I do not know what to install".

It costs two things. The first is installing it — `apt install apt-file` — and the second is a
separate index download, `apt-file update`, which is not small:

```
root@vm:~# du -sh /var/lib/apt/lists
346M    /var/lib/apt/lists
```

Most of that 346 MB is the `Contents` files `apt-file update` fetched. **That is why it is not
installed by default**: it is worth it on a machine where you build things, and skippable on a
server where you already know what you are installing.

`apt-file list poppler-utils` is the other direction — everything a package would install, without
installing it.

`dnf provides '*/pdftotext'` does the same job on the rpm side with no extra download, because dnf's
repository metadata includes the file lists already.
