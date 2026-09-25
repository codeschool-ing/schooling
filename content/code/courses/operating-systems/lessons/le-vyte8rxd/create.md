---
title: Creating folders and files
version: 1
---

Everything in this lesson happens in one folder, `~/work`, with two files already in it: a backup log and
a list of clients.

```
ana@server:~/work$ mkdir invoices
ana@server:~/work$ mkdir reports/2026/q3
mkdir: cannot create directory ‘reports/2026/q3’: No such file or directory
ana@server:~/work$ mkdir -p reports/2026/q3
ana@server:~/work$ touch notes.txt
ana@server:~/work$ echo "call the printer company" > todo.txt
ana@server:~/work$ ls -F
backup.log  clients.csv  invoices/  notes.txt  reports/  todo.txt
ana@server:~/work$ find reports
reports
reports/2026
reports/2026/q3
```

- `mkdir` makes a folder. `mkdir reports/2026/q3` **failed**, because `reports` and `2026` did not
  exist yet. **`-p`** makes the missing parents too, and says nothing if they already exist, which is why
  scripts always use it.
- `touch` creates an empty file, or, if the file exists, only updates its date. It changes no
  contents either way.
- `echo "…" > todo.txt` creates a file with one line in it. The `>` sends the output of `echo` into
  the file instead of the screen, the subject of section 03.
- `ls -F` marks folders with a `/`, and `find` lists everything below a folder, however deep.

Most commands that succeed **print nothing**. The silence is the answer; errors are the only thing
worth printing, and `mkdir` showed one.
