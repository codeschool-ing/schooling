---
title: root, sudo, and the record of every use
version: 1
---

**Ubuntu locks root.** There is a root account with ID 0, and nobody can log in to it:

```
ana@server:~$ sudo passwd -S root
root L 2026-09-25 0 99999 7 -1
ana@server:~$ sudo passwd -S ana
ana P 2026-09-25 0 99999 7 -1
```

`root L`: no usable password. ana has `P`. Administration on Ubuntu happens **through sudo**, as a
person, one command at a time, and that design has three consequences worth knowing.

**1. You can ask what you are allowed.**

```
ana@server:~$ sudo -l
Matching Defaults entries for ana on server:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin, use_pty, env_keep+=DEBIAN_FRONTEND

User ana may run the following commands on server:
    (ALL : ALL) ALL
    (ALL) NOPASSWD: ALL
```

`(ALL : ALL) ALL` is the sudo group's rule: any command, as any user. The `NOPASSWD` line is this test
machine's staging, the reason no transcript in this course shows sudo asking for a password; a real
installation does not have it. The rules live in **`/etc/sudoers`** and the files in
`/etc/sudoers.d/`, and they are edited only with `visudo`, which refuses to save a file with a
mistake in it. A broken sudoers file is how an administrator locks themselves out.

**2. Every use is recorded, with who asked.**

```
ana@server:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep COMMAND | tail -3
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/passwd -S root
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/passwd -S ana
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/journalctl _COMM=sudo --no-pager -o cat
```

Each line says *who* (`ana`), *from where*, *as whom* and *exactly what*. On a machine several
people administer, that is the answer to "who changed this?", which `root` logging in directly would
never give: every root session looks the same.

**3. It asks for your own password.** `su` asked for carla's. `sudo` asks for **yours**, because the
question is not "do you know root's secret" but "are you still the person who sat down", and the rules
decide the rest.

## `sudo -i` and `sudo -s`

Both open a whole root shell, lesson 8's `#` prompt. The record then shows one command, the shell, and
nothing typed inside it. **Prefer single commands**, and when a root shell is needed, leave it as soon
as the work is done.
