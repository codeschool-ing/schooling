---
title: Reading a file without opening all of it
version: 1
---

```
ana@server:~/work$ cat clients.csv
id,name,city
1,Acme Ltd,Sao Paulo
2,Bravo & Filhos,Campinas
3,Casa Verde,Santos
ana@server:~/work$ wc -l backup.log clients.csv
 240 backup.log
   4 clients.csv
 244 total
ana@server:~/work$ head -3 backup.log
2026-09-01 09:00 backup ok
2026-09-01 09:01 backup ok
2026-09-01 09:02 backup ok
ana@server:~/work$ tail -2 backup.log
2026-09-24 09:58 backup ok
2026-09-24 09:59 backup ok
ana@server:~/work$ grep -c ok backup.log
240
```

- `cat` prints a whole file. It is right for a short one, like the four-line list of clients.
- `wc -l` counts lines first: the log has **240**. Nobody reads 240 lines to find out whether last
  night's backup ran.
- `head` shows the start and `tail` the end. `tail -2` answered the real question, the last two
  backups, in two lines.
- `grep -c ok` counted the lines containing `ok`: all 240. A log where that count is lower than the
  line count has a failure in it, and `grep` without `-c` would print which lines.

Two more for longer work: `less` opens a file to scroll, search with `/` and quit with `q`, and
**`tail -f`** keeps printing new lines as a program writes them, which is how a log is watched while
something is being tested. Lesson 17 uses both on the system's own logs.
