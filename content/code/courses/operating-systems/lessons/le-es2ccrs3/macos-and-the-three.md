---
title: macOS, and the three side by side
version: 1
---

**macOS uses both models.** Underneath it is Unix: every file has an owner, a group and the nine letters
of section 01, and Terminal's `ls -l` shows them exactly as on Linux. **On top, it supports ACLs** in the
Windows style, which Finder's *Get Info > Sharing & Permissions* edits when you add a named person.

```sh
ls -le ~/Shared                       # -e adds the ACL entries under each line
chmod +a "bruno allow read" plan.txt  # add an entry, as on Windows
```

**Neither was run for this lesson.** `ls -le` lists the ACL entries under each file that has any; most
files have none.

## A third kind of permission

A Mac adds something neither of the others has in the same form: **privacy permissions**. Even with
full Unix permissions on a file, an app cannot read the Documents folder, the camera or the whole disk
until the person allows it in *System Settings > Privacy & Security*. A backup program that "cannot see
some files" on a Mac usually needs **Full Disk Access** there, whatever `ls -l` says.

## Side by side

| | Linux | Windows | macOS |
|---|---|---|---|
| basic model | owner, group, others | access control list | owner, group, others |
| lists of named entries | optional (ACLs) | always | optional (ACLs) |
| a deny rule | no | yes | yes, in ACLs |
| inherited from the folder | mostly not: the umask decides | yes | the folder's group, and ACL entries |
| to see them | `ls -l` | *Security* tab, `icacls` | `ls -le`, *Get Info* |
| who may change owners | root | administrators | root |

The habit that carries across all three: **grant to groups, not to people**. A group named for a job,
*accounts*, survives the day somebody changes job; a permission granted to a person has to be found and
removed by hand.
