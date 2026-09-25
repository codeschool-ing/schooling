---
title: Deleting, with no Recycle Bin
version: 1
---

```
ana@server:~/work$ rm invoices/*.tmp
ana@server:~/work$ ls invoices
april.pdf  clients-backup.csv  march.pdf  may.pdf
ana@server:~/work$ rmdir reports-copy
rmdir: failed to remove 'reports-copy': Directory not empty
ana@server:~/work$ rm -r reports-copy
ana@server:~/work$ rm -i notes.txt
rm: remove regular empty file 'notes.txt'? n
ana@server:~/work$ ls
backup.log  clients.csv  invoices  notes-todo.txt  notes.txt  reports
```

- `rm` deletes files. `rm invoices/*.tmp` removed the two names `echo` had shown in section 04, and
  nothing else.
- `rmdir` deletes only an **empty** folder, and refused `reports-copy`. That refusal is a safety
  net: it cannot remove anything you have not already emptied.
- `rm -r` deletes a folder and everything in it, at any depth.
- `rm -i` asks about each file. Answering `n` kept `notes.txt`.

**There is no Recycle Bin on the command line.** A file removed by `rm` is gone as far as the system is
concerned; getting it back means a backup. So the habits, in order:

1. **Look first.** `ls` or `echo` the exact pattern you are about to delete, and read the list.
2. **Be where you think you are.** `pwd` before `rm -r`, because a relative path deletes something
   different in every folder, lesson 8's point with a sharper edge.
3. **Never `rm -r` a path built from a variable you have not checked.** An empty variable turns
   `rm -r $DIR/*` into `rm -r /*`.
4. **Use `-i` when the list is short** and you are not certain.

## Windows and macOS

On both, deleting from the command line also skips the Recycle Bin and the Trash. **`del`** and
`Remove-Item` on Windows and `rm` on a Mac are as final as here.
