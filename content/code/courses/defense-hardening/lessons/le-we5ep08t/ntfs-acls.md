---
title: NTFS permissions on Windows
version: 1
---

**Nothing in this section was run for this course.** The lab has no Windows machine. What follows is
Windows' documented behaviour, and the commands are shown as Microsoft documents them, with no
transcript.

Windows has no nine bits underneath: every file and folder on NTFS has an access control list from
the start, and that list is all there is. Each entry, an **access control entry** (ACE), names a user
or group, a set of rights, and whether it **allows** or **denies** them. The rights are finer than
Linux's three: read, write, execute, delete, change permissions and take ownership are separate, and
the common bundles are called Read, Read & execute, Modify and Full control.

## Two differences that matter

**Deny entries exist, and at the same level they win.** Windows evaluates explicit entries before
inherited ones, and within each, deny before allow. So an explicit deny for a group overrides an
explicit allow for a user who is in it, which is the opposite of the Linux surprise in the last section.
On Linux a named user entry can
restrict a member of a generous group; on Windows a deny on the group restricts the user whatever
their own entry says. Microsoft's advice is to use deny sparingly, because the result of mixing them
is hard to read.

**Inheritance is the normal case.** On Linux a default ACL is something you add. On NTFS, permissions
flow down from each folder to everything inside it unless inheritance is broken, and most of a file
system's permissions are inherited rather than written on the file. An entry can say how far it
travels: this folder only, subfolders, files, or all of them. Breaking inheritance on a folder, to
give it a list of its own, is the equivalent of Linux's `setfacl` on one directory, and it is the
place a forgotten exception usually hides.

## icacls

`icacls` is the command-line tool, and its answers read like `getfacl`'s:

```
icacls D:\Clientes
icacls D:\Clientes /grant "JATOBA\Auditoria:(OI)(CI)R"
icacls D:\Clientes /inheritance:r
```

The first lists each entry with its rights in short form, `(F)` for full control, `(M)` modify,
`(RX)` read and execute, `(R)` read, and the inheritance flags `(OI)` object inherit (files) and
`(CI)` container inherit (folders); an `(I)` marks an entry that was inherited. The second grants the
auditor read on the folder and everything under it, which is this lesson's `setfacl -m` and `setfacl -d`
in one. The third removes the inherited entries and keeps only explicit ones, which is how a folder
stops trusting its parent.

The same advice as on Linux applies. Grant to groups rather than to people, so that a person who
changes jobs changes groups and not a hundred lists. Ask the system what a person can actually do,
with the **Effective Access** tab in a folder's advanced security settings, rather than reading the
list and adding it up in your head.
