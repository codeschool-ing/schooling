---
title: Reading a configuration file
version: 1
---

Most configuration files are **mostly comments**. The journal's is a good example:

```
ana@server:~$ wc -l /etc/systemd/journald.conf
49 /etc/systemd/journald.conf
ana@server:~$ grep -Ev '^(#|$)' /etc/systemd/journald.conf
[Journal]
ana@server:~$ grep -n 'Storage' /etc/systemd/journald.conf
20:#Storage=auto
ana@server:~$ ls /etc/apt/apt.conf.d
01-vendor-ubuntu
01autoremove
70debconf
90proxy
99capture-plain
```

**49 lines, and one of them is a setting**: `[Journal]`, a section heading, with nothing under it.
Everything else starts with `#`. The file lists every option **commented out, with its default value**:
`#Storage=auto` says that storage is automatic unless somebody removes the `#` and changes it.

That convention answers two questions at once. **What can be set** is the whole file. **What is set**
is the lines without `#`, and `grep -Ev '^(#|$)'` shows exactly those: it hides comments and empty
lines. On a server somebody else configured, that command on each file in `/etc` is the fastest way to
see what they changed.

## The `.d` folders

`/etc/apt/apt.conf.d` is a **folder of small files** that apt reads in name order, instead of one large
file. Each package or administrator adds its own file rather than editing a shared one, and removing
the setting means deleting one file. The numbers at the front set the order.

`99capture-plain` in that list is this course's own: the file that makes apt print plain progress lines
in lesson 11. `90proxy` is the capture machine's route to the internet. A real installation has neither.
