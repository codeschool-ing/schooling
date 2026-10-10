---
title: Reading a log
version: 1
---

A server log is read in two situations: **something is wrong now**, and you want the lines from
the last few minutes, or **something was wrong once**, and you want every line of one kind. Both
start from the word after the prefix, the **severity**.

| severity | what it means |
|---|---|
| `LOG` | information for the administrator: a checkpoint, a slow statement, a connection |
| `WARNING` | something probably not intended, which went ahead anyway |
| `ERROR` | one statement failed; the session carries on |
| `FATAL` | one session ended: a refused login, a terminated backend |
| `PANIC` | the whole server stopped, and every session with it |
| `DETAIL`, `HINT`, `CONTEXT`, `STATEMENT` | more about the line above, from the same process |

`ERROR`, `FATAL` and `PANIC` go up in how much they took down with them, and **`FATAL` is the one
people misread**: it sounds like the end of the server and usually means one connection was turned
away. `log_min_messages`, `warning` by default, is the lowest severity the server writes, and
lowering it to `info` or `debug1` adds far more noise than it adds answers.

## Counting before reading

The log has had a busy lesson. Before opening it, count what is in it:

```
ana@db:~$ sudo grep -oE '(LOG|ERROR|FATAL|PANIC|WARNING|DETAIL|HINT|CONTEXT|STATEMENT): ' /var/log/postgresql/postgresql-16-main.log | sort | uniq -c | sort -rn
 140060 LOG: 
      9 STATEMENT: 
      2 ERROR: 
      2 CONTEXT: 
      1 DETAIL: 
ana@db:~$ sudo grep -E 'ERROR|FATAL|PANIC' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:27.696 -03 [211] ana@shop ERROR:  division by zero
2026-10-10 16:44:29.187 -03 [220] ana@shop psql ERROR:  division by zero
```

140,060 `LOG` lines, almost all of them the two runs of the previous section at 70,000
statements each, and two errors. The two errors are the
`SELECT 1/0` of the prefix section, and `grep` found them in a file where they were lost among the
statements of the last section. **On a server under pressure, start with this `grep`**, then take
the process id from the prefix of a line that matters and `grep` for `[that pid]` to see everything
that one session wrote.

`tail -f` on the file follows it live, which is right while you reproduce a problem and useless for
anything that already happened. `less +G` opens a large file at its end without reading it all
into memory first.

## Rotation

A log that only grows fills the disk, and lesson 9 shows what PostgreSQL does when that happens.
On Ubuntu the file is cut by **logrotate**, the same tool that rotates every other log on the
machine, following this file:

```
ana@db:~$ cat /etc/logrotate.d/postgresql-common
/var/log/postgresql/*.log {
       weekly
       rotate 10
       copytruncate
       delaycompress
       compress
       notifempty
       missingok
       su root root
}
```

Weekly, ten old files kept, compressed from the second one on (`delaycompress`). Forcing a rotation
now shows the result:

```
ana@db:~$ sudo logrotate -f /etc/logrotate.d/postgresql-common
ana@db:~$ ls -l /var/log/postgresql
total 18484
-rw-r----- 1 postgres adm        0 Oct 10 16:45 postgresql-16-main.log
-rw-r----- 1 postgres adm 18925723 Oct 10 16:45 postgresql-16-main.log.1
```

The line to understand is **`copytruncate`**. The server holds the file open as its standard error
and has no way to be told to reopen it, so logrotate cannot simply rename the file: the server
would go on writing into the renamed one. Instead it copies the contents to `.1` and then truncates
the original to zero, and the server carries on writing at the start of an empty file. The price is
a small window between the copy and the truncation in which lines written are in neither file.

**Weekly is a size decision made without looking at the size.** With `log_statement = 'all'` the
previous section wrote megabytes in seconds, and a week of that would be a disk. If the logging you
choose writes a lot, rotate daily, or by size with logrotate's `size` or `maxsize`, and check the
partition `/var/log` lives on.
