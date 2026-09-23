---
title: `chmod`, and what recursion does to directories
version: 2
---

`chmod` takes the mode two ways. **Numeric** sets all nine bits at once. **Symbolic** changes the
ones you name and leaves the rest alone. They are not interchangeable, and knowing which one you
want is most of using it well.

```
chmod 644 report.txt      # numeric: the whole mode becomes this
chmod u+x script.sh       # symbolic: add one bit, touch nothing else
```

## Symbolic, which is three parts

```localised
chmod  [ugoa]  [+-=]  [rwx]  file
```

**Who**: `u` owner, `g` group, `o` other, `a` all three. Leave it out and it means `a`, filtered by
your umask — which is section 09, and a good reason to be explicit.

**How**: `+` add, `-` remove, `=` set exactly this and clear the rest of that row.

**What**: `r`, `w`, `x` — and two more below.

```
ana@vm:~/cm$ ls -l a.txt
-rw-r--r-- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod u+x a.txt
ana@vm:~/cm$ ls -l a.txt
-rwxr--r-- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod g+w,o-r a.txt
ana@vm:~/cm$ ls -l a.txt
-rwxrw---- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod a=r a.txt
ana@vm:~/cm$ ls -l a.txt
-r--r--r-- 1 ana ana 5 Sep 14 22:52 a.txt
```

Three commands, three different verbs. `+x` added a bit. `g+w,o-r` did two changes in one go —
**comma-separated, no spaces**. And `a=r` set every row to exactly `r--`, which wiped the `w` and
the `x` that were there.

`=` is the sharp one. It is the only symbolic form that can take permissions **away** without you
naming them.

Two more forms worth having:

```
ana@vm:~/cm$ chmod u=rw,g=r,o= a.txt
ana@vm:~/cm$ ls -l a.txt
-rw-r----- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod g=u a.txt
ana@vm:~/cm$ ls -l a.txt
-rw-rw---- 1 ana ana 5 Sep 14 22:52 a.txt
```

`o=` with nothing after it means *no permissions for other*, and it is the shortest way to shut
strangers out. `g=u` means *give the group whatever the owner has*, copying one row onto another.

And copying from another file entirely:

```
ana@vm:~/cm$ chmod --reference=run.sh a.txt
ana@vm:~/cm$ ls -l a.txt run.sh
-rwxr-xr-x 1 ana ana  5 Sep 14 22:52 a.txt
-rwxr-xr-x 1 ana ana 20 Sep 14 22:52 run.sh
```

`--reference` is how you make one file match another without reading the mode and retyping it —
useful when you have twenty files and one of them is right.

## Numeric, which replaces everything

`chmod 640 report.txt` sets the mode to exactly `-rw-r-----`, whatever it was before. There is no
partial form: you are stating all nine bits.

**Use numeric when you know the answer.** `chmod 644`, `chmod 755`, `chmod 600` — these are shapes,
and stating a shape in one word is clearer than arriving at it in three steps.

**Use symbolic when you want to change one thing.** `chmod +x` on a script you downloaded says
exactly what you mean and cannot accidentally open the file to the world.

There is one trap worth repeating from section 04: **a three-digit number clears the special
bits.** `chmod 755` on a file that was `4755` silently turns setuid off. Symbolic form does not do
that.

## `-R`, and the mistake it makes easy

`-R` applies the change to a directory and everything under it. It is the right tool for "this
whole tree should belong to the group", and it is a loaded gun for one reason: **files and
directories do not want the same bits.**

Watch:

```
ana@vm:~/cm$ ls -l
total 12
-rw-r--r-- 1 ana ana    5 Sep 14 22:52 a.txt
-rwxr-xr-x 1 ana ana   20 Sep 14 22:52 run.sh
drwxr-xr-x 2 ana ana 4096 Sep 14 22:52 sub
ana@vm:~/cm$ chmod -R 644 .
chmod: cannot read directory '.': Permission denied
ana@vm:~/cm$ ls -l
ls: cannot open directory '.': Permission denied
```

Read what happened. `644` is a sensible mode **for a file**. Applied to the directory it stripped
the `x`, and without `x` a directory cannot be entered — so `chmod` could not continue into it, and
the shell sitting in it could no longer list it. One command, and the tree locked itself.

It is recoverable from outside, and this is the fix worth memorising:

```
ana@vm:~$ ls -ld cm
drw-r--r-- 3 ana ana 4096 Sep 14 22:52 cm
ana@vm:~$ chmod -R u+rwX,go+rX cm
ana@vm:~$ ls -ld cm cm/sub
drwxr-xr-x 3 ana ana 4096 Sep 14 22:52 cm
drwxr-xr-x 2 ana ana 4096 Sep 14 22:52 cm/sub
ana@vm:~$ ls -l cm
total 12
-rw-r--r-- 1 ana ana    5 Sep 14 22:52 a.txt
-rwxr-xr-x 1 ana ana   20 Sep 14 22:52 run.sh
drwxr-xr-x 2 ana ana 4096 Sep 14 22:52 sub
```

**`X` — capital — is the whole trick.** It means *execute, but only for directories and for files
that already have execute somewhere*. So the directories got their `x` back, `run.sh` kept its,
and `a.txt` stayed `644` as it should.

```
chmod -R u+rwX,go+rX tree/
```

That line is the safe recursive default, and it is worth putting somewhere you can find it. The
unsafe version people reach for first is `chmod -R 755`, which makes every text file in the tree
executable.

## Who may change a mode

**The owner, and root.** Not the group, however generous the bits look. Being able to write a file
does not let you change who else can write it — that would make the whole model meaningless.

```
bruno@vm:/srv/perm$ ls -l teamonly.txt
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
bruno@vm:/srv/perm$ chmod g+w teamonly.txt
chmod: changing permissions of 'teamonly.txt': Operation not permitted
```

Bruno is in `team`. He can read the file. He cannot decide who else may.

Note the wording: **`Operation not permitted`, not `Permission denied`.** The second means the bits
said no; the first means you are not allowed to attempt this at all. Section 07 is about how
ownership moves, and section 11 is about the one account that ignores all of it.
