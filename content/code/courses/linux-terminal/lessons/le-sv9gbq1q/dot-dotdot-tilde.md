---
title: The shorthands: `.`, `..`, `~` and `-`
version: 1
---

Four pieces of shorthand appear in almost every path you will ever type. Two of them are real
directory entries the kernel knows about; two are text the shell rewrites before the command sees
anything. **That difference decides where each one works**, so it is worth getting straight now.

| | means | who handles it |
|---|---|---|
| `.` | this directory | the **kernel** — it is a real entry |
| `..` | the directory above | the **kernel** — it is a real entry |
| `~` | your home directory | the **shell** — it is expanded, then thrown away |
| `-` | the directory you were in before | the **shell**, and only for `cd` |

## `.` and `..` are really there

They are not a convention. Every directory on the filesystem contains two entries called `.` and
`..`, put there when the directory was made:

```
ana@vm:~/work$ ls -a
.  ..  .env  Makefile  README.md  build  data  logs  notes  src
```

`-a` showed them because they begin with a dot, like any other hidden name. But unlike `.env`,
they were not created by anybody.

**`.` is used far more than beginners expect**, because a lot of commands want a destination and
"here" is a destination:

```
cp ~/Downloads/report.csv .        # copy it here
tar -xzf backup.tar.gz -C .        # extract here
find . -name '*.log'               # search from here down
```

`..` is how you go up, and it composes:

```
ana@vm:~/work$ cd ..
ana@vm:~$ cd work/src
ana@vm:~/work/src$ cd ../notes
ana@vm:~/work/notes$ pwd
/home/ana/work/notes
```

`../notes` is "up one, then down into notes" — a sideways move, and by far the most common use of
`..` in practice.

### At the root, `..` stops

```
ana@vm:/$ cd ..
ana@vm:/$ pwd
/
```

No error, no complaint, and no movement. `/` is the top, so `/..` is `/` — and that is not the
shell being kind, it is literally true on disk:

```
ana@vm:/$ ls -di / /.. /.
2 /  2 /.  2 /..
```

`-i` prints the inode number, which is the filesystem's own identifier for a thing (section 11).
All three are inode 2. They are one directory with three names.

## `~` is expanded by the shell

```
ana@vm:~$ echo ~
/home/ana
ana@vm:~$ echo ~root
/root
```

`echo` prints what it was handed, and it was handed `/home/ana`. **The tilde never reached it.**
The shell replaced it while parsing the line, which is the same machinery that expands `*` in
section 10.

| you type | becomes |
|---|---|
| `~` | your home directory |
| `~/work` | `/home/ana/work` |
| `~root` | root's home, `/root` |
| `~ana` | ana's home, wherever the system says it is |

The last two are genuinely useful when you are logged in as somebody else and want to name a
person's home without knowing the layout.

**Where `~` does not work**: anywhere the shell is not reading the line. In a configuration file,
in a crontab field, inside single quotes, or in an argument some program parses itself, `~` is just
a character:

```
ana@vm:~$ echo '~/work'
~/work
```

That is why `/etc` is full of `/home/somebody/...` written out in full. It is not verbosity; it is
that nothing would expand the shorthand.

## `-` means "back"

```
ana@vm:~$ cd /tmp
ana@vm:/tmp$ cd -
/home/ana
ana@vm:~$ pwd
/home/ana
```

`cd -` returns to the previous directory, and prints where it landed — that line of output is
`cd` telling you, not an error. Press it twice and you are back where you started, which makes it
a toggle between two places you are working in.

**It only works for `cd`.** `ls -` is not "list the previous directory"; it is `ls` being handed
something that looks like an option and does not exist.

## Two places these shorthands surprise people

### `.` is not in `$PATH`, on purpose

```
ana@vm:~/work$ ./ledger
```

You must write `./` to run a program sitting in the current directory. The reason is security:
if `.` were searched automatically, dropping a file called `ls` into a shared directory would be
enough to have the next person run it. Section 03 already made the mechanical point; this is why
nobody has ever fixed it.

### A trailing `/.` forces "the contents of"

`cp -r src dest` and `cp -r src/. dest` behave differently when `dest` already exists, and the
difference is whether you copy *the directory* or *what is in it*. You will meet this the first
time a copy produces `dest/src/` when you wanted `dest/`. The reliable habit is to check with `ls`
straight afterwards rather than to memorise the rule — and section 07 shows the same trap for `mv`.
