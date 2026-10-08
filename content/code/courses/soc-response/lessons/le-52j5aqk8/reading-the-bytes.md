---
title: Reading the bytes
version: 1
---

Every tool so far interprets the disk: names, inodes, files. Sometimes the examiner needs the bytes themselves,
with no interpretation, to check what a tool claimed or to look at something no tool understands. That is a
**hex editor**'s job. **WinHex**, from X-Ways, is the one most often named in forensic work; it is commercial
Windows software and **was not run here**. Its central view, offsets on the left, bytes in hexadecimal in the
middle and the same bytes as text on the right, is what `xxd` prints on Linux.

`blkcat` reads one block by number, the content layer of the figure, and `xxd` shows it:

```
root@soc:~/case# blkcat work.dd 1561 | xxd | head -6
00000000: 636c 6965 6e74 2c63 6f6e 7461 6374 2c65  client,contact,e
00000010: 6d61 696c 0d0a 6163 6d65 2d6c 6f67 6973  mail..acme-logis
00000020: 7469 6361 2c47 7573 7461 766f 2041 6c76  tica,Gustavo Alv
00000030: 6573 2c67 7573 7461 766f 4061 636d 652d  es,gustavo@acme-
00000040: 6c6f 6769 7374 6963 612e 6578 616d 706c  logistica.exampl
00000050: 650d 0a62 656e 746f 2d61 6476 6f67 6164  e..bento-advogad
```

The left column is the **offset** inside the block, in hexadecimal: `00000010` is byte 16. The middle is sixteen
bytes per line, in pairs. The right is the same bytes as text, with a dot for anything that is not printable.
The deleted file is right there in block 1561, starting at its first byte.

Two details show why the raw view matters. `0d0a` at the end of each line is a carriage return and a line feed,
the Windows line ending, which Python's `csv` module writes by default: a tool that showed "the text" would hide
it, and it can matter when two files are compared byte for byte. And the block is 4,096 bytes while the file is
313: everything after byte 313 in this block is **slack**, whatever was there before, which on a used disk can
be the remains of an older file.
