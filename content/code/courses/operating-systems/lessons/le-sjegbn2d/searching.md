---
title: Finding files, and finding words inside them
version: 1
---

Again two questions: **which files are called this**, and **which files contain this**.

```
ana@server:~$ find work -name '*.txt'
work/invoices/104.txt
work/reports/q3.txt
ana@server:~$ grep -rn "Acme" work
work/invoices/104.txt:1:Invoice 104 for Acme Ltd
work/clients.csv:2:1,Acme Ltd,Sao Paulo
PS /home/ana> Get-ChildItem work -Recurse -Filter *.txt -Name
invoices/104.txt
reports/q3.txt
PS /home/ana> Select-String -Path work/*/*.txt, work/*.csv -Pattern Acme

work/invoices/104.txt:1:Invoice 104 for Acme Ltd
work/clients.csv:2:1,Acme Ltd,Sao Paulo
```

- **`find`** searches by **name** (and size, date, owner), walking down from a folder. The pattern is
  quoted, so that `find` receives the `*` rather than the shell expanding it first, lesson 12's point.
- **`grep -rn`** searches **inside** files: `-r` walks folders, `-n` prints the line number. It found
  `Acme` in the invoice and in the client list.
- **`Get-ChildItem -Recurse -Filter`** is PowerShell's `find`, and **`Select-String`** is its `grep`,
  printing the file, line number and line in the same form.

In the Command Prompt:

```sh
dir /s /b *.txt
findstr /s /i /n "Acme" *.txt
```

`dir /s /b` lists every matching file below the current folder, one full path per line, and **`findstr`**
is the Command Prompt's `grep`: `/s` for subfolders, `/i` to ignore case, `/n` for line numbers. On
Windows the search box in File Explorer does the same for people; the commands are for when the results
need to go somewhere, into a file or the next command.
