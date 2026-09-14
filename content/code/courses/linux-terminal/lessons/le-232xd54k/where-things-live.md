---
title: A first map of the tree
version: 1
---

The tree has a shape, and it is the same shape on every distribution — that is what the Filesystem
Hierarchy Standard is for. Lesson 3 walks it directory by directory. **This section is the map you
need to stop feeling lost**, which is about eight names.

## The eight that matter now

| | what is in it |
|---|---|
| `/etc` | **configuration**, for the whole machine. Text files, all of it |
| `/home` | one directory per person. Yours is `/home/you`, and `~` is short for it |
| `/var` | things that **change while the machine runs** — logs above all |
| `/usr` | the programs and their data. Most of what is installed lives here |
| `/tmp` | scratch space, wiped on reboot |
| `/root` | the administrator's home. **Not** the root of the tree, which is `/` |
| `/opt` | software installed outside the package manager |
| `/dev`, `/proc` | the devices and the kernel, as files — section 09 |

## What they actually look like

**`/etc` is configuration, and it is all text.**

```
ana@vm:~$ ls /etc | head -12
PackageKit
X11
adduser.conf
alternatives
apparmor.d
apt
bash.bashrc
bash_completion.d
bazel.bazelrc
bindresvport.blacklist
binfmt.d
ca-certificates
```

Directories and files, named after what configures them. **There is no registry.** Everything that
decides how this machine behaves is a file you can read with `cat`, search with `grep`, compare
with `diff` and keep in git. That last one is not a metaphor: putting `/etc` under version control
is a normal thing to do, and it is possible only because of what these files are.

**`/var` is what changes.**

```
ana@vm:~$ ls /var
backups
cache
lib
local
lock
log
mail
opt
run
spool
tmp
```

`log` is the one you will live in. Lesson 5 reads it properly; lesson 11 goes there when something
is wrong. The rule of thumb that makes `/var` make sense: *if the machine writes it while running,
it is here.*

**`/usr` is what was installed.**

```
ana@vm:~$ ls /usr
bin
games
include
lib
lib64
libexec
local
sbin
share
src
```

`bin` is programs, `lib` is what they load, `share` is data that does not depend on the processor
— icons, documentation, translations. `local` is the exception worth knowing: `/usr/local` is for
software **you** installed by hand, kept separate so the package manager never fights you for it.

**`/home` is people.**

```
ana@vm:~$ ls /home
ana
claude
ubuntu
user
```

Four accounts on this machine, four directories. Yours is the only one you can write in, and
mostly the only one you can read — section 14 is about why.

## Against Windows, where it is the same idea arranged differently

| | Linux | Windows |
|---|---|---|
| your documents | `/home/you` | `C:\Users\you` |
| machine configuration | `/etc`, as text | the registry, as a database |
| your settings | dotfiles in `/home/you` | `AppData`, and the registry |
| installed programs | `/usr`, spread by kind | `C:\Program Files`, one folder each |
| logs | `/var/log`, as text | Event Viewer |
| scratch | `/tmp` | `C:\Windows\Temp`, `%TEMP%` |

**The difference that matters is not the names, it is the format.** Linux configuration is text in
files, so every tool in lesson 8 works on it, and a change is a diff somebody can read. Windows
configuration is largely a binary database reached through its own tools.

That is why this course spends a whole lesson on text: on Linux, text *is* the administration
interface.

## Two things people get wrong immediately

**`/root` is not `/`.** `/` is the top of the tree. `/root` is the administrator's home directory,
which sits inside it, and the two are different words that happen to share a syllable.

**`/usr` is not "user".** It is where programs live, not people. People are in `/home`. The name is
historical and misleads everybody exactly once.
