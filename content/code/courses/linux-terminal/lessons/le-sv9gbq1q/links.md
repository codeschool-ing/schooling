---
title: Inodes, hard links and symlinks
version: 1
---

A filename is not a file. **The file is a numbered thing on the disk, and a filename is an entry
in a directory that points at that number.** Once that sentence is real to you, everything in this
section is obvious — and several things you have already seen stop being strange.

The number is called the **inode**, and `ls -i` prints it:

```
ana@vm:~/hard$ ls -li
total 4
573516 -rw-r--r-- 1 ana ana 13 Sep 14 22:20 report.txt
```

`573516` is what the filesystem calls this data. `report.txt` is what the directory calls it. The
inode holds everything `ls -l` showed you — permissions, owner, size, timestamps, and where the
bytes are. **The name is not in the inode.** The name is in the directory.

## A hard link is a second name for the same inode

```
ana@vm:~/hard$ ln report.txt hardlink.txt
ana@vm:~/hard$ ls -li
total 8
573516 -rw-r--r-- 2 ana ana 13 Sep 14 22:20 hardlink.txt
573516 -rw-r--r-- 2 ana ana 13 Sep 14 22:20 report.txt
```

Two names. **One inode.** And the link count — field 3 from section 41 — went from `1` to `2`,
because that field is exactly *how many names point here*.

Nothing was copied. There is no original and no copy; there are two names of equal standing, and
the filesystem could not tell you which came first if you asked it. Change one and you change the
other, because there is only one of them:

```
ana@vm:~/hard$ printf 'changed\n' > report.txt
ana@vm:~/hard$ cat hardlink.txt
changed
```

And now the part that surprises people:

```
ana@vm:~/hard$ rm report.txt
ana@vm:~/hard$ ls -li
total 4
573516 -rw-r--r-- 1 ana ana 8 Sep 14 22:20 hardlink.txt
ana@vm:~/hard$ cat hardlink.txt
changed
```

**`rm` did not delete the file.** It removed a name and decremented the count, from 2 back to 1.
The data is still there, reachable through the other name — and it will stay there until the last
name pointing at it goes away.

That is what `rm` has always done. On a file with one name, removing the name and removing the
data look like the same event, which is why nobody notices. `unlink` is the actual system call,
and it is named honestly.

## A symbolic link is a name that contains a path

A fresh directory, one file, and a link made with `-s`:

```
ana@vm:~/soft$ ln -s report.txt softlink.txt
ana@vm:~/soft$ ls -li
total 4
573518 -rw-r--r-- 1 ana ana 13 Sep 14 22:20 report.txt
573519 lrwxrwxrwx 1 ana ana 10 Sep 14 22:20 softlink.txt -> report.txt
```

Three differences from a hard link, and each one matters:

- **its own inode**, `573519` — it is a separate thing on disk;
- **type `l`** in the first column — section 41's field 1, earning its keep;
- **size 10**, which is the length of the string `report.txt`. That is all a symlink is: a tiny
  file whose contents are a path.

Opening it works, because the kernel reads the path inside and starts again from there:

```
ana@vm:~/soft$ cat softlink.txt
the original
```

And then:

```
ana@vm:~/soft$ rm report.txt
ana@vm:~/soft$ cat softlink.txt
cat: softlink.txt: No such file or directory
ana@vm:~/soft$ ls -l softlink.txt
lrwxrwxrwx 1 ana ana 10 Sep 14 22:20 softlink.txt -> report.txt
```

**The link is fine. What it points at is gone.** `ls` shows it happily — it is a real file with
real permissions — and everything that tries to *follow* it fails. That is a dangling symlink, and
it is the most common way a symlink surprises you.

You can make one pointing at nothing at all, and nothing objects:

```
ana@vm:~/soft$ ln -s /etc/nothing-here broken.txt
ana@vm:~/soft$ ls -l broken.txt
lrwxrwxrwx 1 ana ana 17 Sep 14 22:20 broken.txt -> /etc/nothing-here
```

`ln -s` does not check, because the target is allowed to arrive later — that is a feature, and it
is how a link into a disk that has not been mounted yet is supposed to behave.

## The two, side by side

| | hard link | symbolic link |
|---|---|---|
| made with | `ln a b` | `ln -s a b` |
| is | another name for one inode | a small file holding a path |
| own inode? | no | yes |
| shows in `ls -l` as | an ordinary file | `l`, with `-> target` |
| survives deleting the target | **yes** — it *is* the target | no, it dangles |
| can cross filesystems | no | yes |
| can point at a directory | no | yes |
| can point at something that does not exist | no | yes |

**Two of those restrictions are why symlinks exist at all.** A hard link cannot cross a
filesystem, because an inode number only means something inside one filesystem. And a hard link to
a directory is forbidden, because it would let you build a loop that `find` could walk forever.

In practice: **you will use symlinks, nearly always.** Hard links turn up in backup tools that
deduplicate, and in the answer to "why did deleting the log not free any space" — section 48.

## Relative and absolute, again

A symlink stores whatever path you gave it, unchanged:

```
ana@vm:~/soft$ ln -s ../soft/report.txt rel.txt
ana@vm:~/soft$ ls -l rel.txt
lrwxrwxrwx 1 ana ana 18 Sep 14 22:20 rel.txt -> ../soft/report.txt
ana@vm:~/soft$ cat rel.txt
back again
```

**A relative link is resolved from the directory the link is in**, not from where you are standing
when you open it. That is the sane behaviour, and it means a relative symlink survives the whole
tree being moved or copied somewhere else.

An absolute link survives the *link* being moved, and breaks when the target moves. Choose by
which of the two is more likely.

Two commands answer "where does this actually go":

```
ana@vm:~/soft$ readlink rel.txt
../soft/report.txt
ana@vm:~/soft$ readlink -f rel.txt
/home/ana/soft/report.txt
```

`readlink` prints the stored text. `readlink -f` follows every link in the chain and prints the
real absolute path at the end of it. The second is what you want when something is three symlinks
deep and you have lost track.

## Where you will actually meet them

**`/bin`, `/lib`, `/sbin`.** Section 37's arrows:

```
ana@vm:~/work$ ls -l /bin
lrwxrwxrwx 1 root root 7 Apr 22  2024 /bin -> usr/bin
ana@vm:~/work$ ls -ld /bin/
drwxr-xr-x 2 root root 36864 Mar 31 13:31 /bin/
```

With `-l`, `ls` describes the link. With a trailing slash, it goes through it. That is the same
pair of commands section 40 showed you, and now you know why they differ.

**Versioned software.** `/usr/lib/libssl.so.3` is real; `/usr/lib/libssl.so` is a symlink to it.
Upgrading moves the link, and nothing that referred to the short name has to change.

**`/etc/alternatives`.** On Debian and Ubuntu, `/usr/bin/editor` is a symlink into a directory of
symlinks, which is how the system lets you choose which editor "the editor" means without moving
any actual program.

**And a trap worth naming once**: `cp -r somelink dest` copies the link rather than what it points
at, unless you add `-L`. When a copy comes out full of dangling links, this is why.
