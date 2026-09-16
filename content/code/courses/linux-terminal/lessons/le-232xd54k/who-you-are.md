---
title: A machine with more than one person on it
version: 1
---

Linux was built in a world where one computer served a department, and **it never stopped assuming
that**. Even on a laptop nobody else touches, the system is arranged as though several people and
several programs share it and should not be able to reach each other's things.

That assumption is why you are not the administrator, and why that is a feature.

## You are a number with a name attached

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana)
```

The name is for you; the number is what the system uses. `uid` is the user, `gid` the primary
group, and `groups` every group you belong to. Lesson 4 is built on these three.

Your account is a line in a text file, like everything else:

```
ana@vm:~$ grep "^ana" /etc/passwd
ana:x:1001:1002::/home/ana:/bin/bash
```

Seven fields, separated by colons:

| field | value here | |
|---|---|---|
| name | `ana` | |
| password | `x` | **not** the password — it means "look in `/etc/shadow`" |
| uid | `1001` | |
| gid | `1002` | the primary group |
| comment | *(empty)* | a full name, historically |
| home | `/home/ana` | where `~` points |
| shell | `/bin/bash` | what starts when you log in — section 03's `$SHELL` |

## Root is uid 0, and it is not a person

```
ana@vm:~$ head -1 /etc/passwd
root:x:0:0:root:/root:/bin/bash
```

**Zero is the whole of it.** The kernel does not check permissions for uid 0; it checks them for
everybody else. Root is not "an account with many permissions" — it is the account the permission
check is skipped for.

Which is why the `#` of section 06 is worth reading before you press enter. There is no dialog, no
"are you sure", and no undo.

## Most of the accounts are not people

```
ana@vm:~$ grep -c "" /etc/passwd
26
```

Twenty-six accounts on a machine with four humans. The rest belong to **programs**: the web server
gets one, the database gets one, the printing system gets one.

This is the deep reason for the multi-user design, and it has nothing to do with sharing a
computer. If the web server runs as its own user, then a flaw in the web server reaches exactly
what that user may reach — not your documents, not the database, not the machine. **The account is
a blast radius.** Lesson 5 creates one; every course after this one relies on it.

## What "you may not" looks like

```
ana@vm:~$ ls -l /etc/shadow
-rw-r----- 1 root shadow 677 Sep 14 13:00 /etc/shadow
ana@vm:~$ cat /etc/shadow
cat: /etc/shadow: Permission denied
```

Read those two lines together and the refusal stops being mysterious. The file is owned by `root`,
its group is `shadow`, and the permissions give the owner read and write, the group read, and
**everybody else nothing** — that is what the three empty slots at the end mean.

`ana` is not root and is not in `shadow`, so `ana` falls into "everybody else". The kernel checked
and said no, exactly as section 03 promised: the shell found `cat`, `cat` asked, and the kernel
refused.

That file holds the password hashes. The permissions on it are the entire reason you cannot read
your colleagues' passwords, and they are nine bits in a listing you can print.

## Why you are not root by default

Windows spent a decade teaching people to click "Yes" on a prompt. Linux takes the other route:
**you are an ordinary user, and becoming root is an explicit act for one command.**

The benefit is not that it stops you doing damage — you can always ask. It is that damage requires
you to have said so. A typo in a command you ran as yourself can destroy your own files. The same
typo as root can destroy the machine.

Section 08 of lesson 4 is `sudo`, which is how you ask. Until then, the useful reflex is the one
from section 06: **look at the last character of the prompt.**
