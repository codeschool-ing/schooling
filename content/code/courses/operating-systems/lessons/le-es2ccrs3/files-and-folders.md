---
title: What each letter allows, on a file and on a folder
version: 1
---

The same three letters mean different things on a file and on a folder, and the difference explains
most permission puzzles.

| | on a file | on a folder |
|---|---|---|
| `r` | read its contents | list the names inside |
| `w` | change its contents | create, rename and **delete** names inside |
| `x` | run it as a program | **enter** it, and reach anything inside |

## Taking read away

```
ana@server:/srv/office$ sudo -u bruno cat payroll.txt
salaries
ana@server:/srv/office$ chmod o-r payroll.txt
ana@server:/srv/office$ ls -l payroll.txt
-rw-r----- 1 ana ana 9 Sep  1 09:00 payroll.txt
ana@server:/srv/office$ sudo -u bruno cat payroll.txt
cat: payroll.txt: Permission denied
```

`o-r` removed read from **o**thers. The next `cat` as bruno was refused, which is the intern problem
solved for this one file.

## A folder without x

```
ana@server:/srv/office$ chmod o-x reports
ana@server:/srv/office$ ls -ld reports
drwxr-xr-- 2 ana ana 4096 Sep  1 09:00 reports
ana@server:/srv/office$ sudo -u bruno ls reports
q3.txt
ana@server:/srv/office$ sudo -u bruno cat reports/q3.txt
cat: reports/q3.txt: Permission denied
ana@server:/srv/office$ chmod o+x reports
```

With `r` and no `x` for others, bruno **could list the names** in `reports` and **could not open the
file inside**, even though `q3.txt` itself is readable by everybody. To reach anything in a folder you
need `x` on it, and on every folder above it. That is also why Ubuntu's home folders keep others out:
without `x` on `/home/ana`, nothing inside is reachable, whatever its own permissions say.

## Deleting is the folder's business

```
ana@server:/srv/office$ mkdir drop && chmod 777 drop
ana@server:/srv/office$ printf "draft\n" > drop/plan.txt && chmod 444 drop/plan.txt
ana@server:/srv/office$ ls -l drop
total 4
-r--r--r-- 1 ana ana 6 Sep 25 10:53 plan.txt
ana@server:/srv/office$ sudo -u bruno sh -c "echo change >> drop/plan.txt"
sh: 1: cannot create drop/plan.txt: Permission denied
ana@server:/srv/office$ sudo -u bruno rm -f drop/plan.txt
ana@server:/srv/office$ ls -l drop
total 0
ana@server:/srv/office$ ls -ld /tmp
drwxrwxrwt 9 root root 180 Sep 25 10:49 /tmp
```

`plan.txt` was **read-only for everybody**, and bruno could not change it. He **deleted it anyway**,
because deleting a name is a change to the folder, and the folder `drop` was writable by all.

**To protect a file from deletion, protect the folder it is in.** Shared folders that must be writable
by everybody use the **sticky bit**, the `t` at the end of `/tmp`'s permissions: in such a folder
people can delete only their own files.
