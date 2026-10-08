---
title: Getting a deleted file back
version: 1
---

`fls -d` lists only the deleted entries, and `istat` reads the inode behind one, here number 24. The output is
long, and `sed -n` keeps the lines that matter:

```
root@soc:~/case# fls -r -d -p work.dd
r/r * 24:	exports/contacts-2026-08.csv
root@soc:~/case# istat work.dd 24 | sed -n '1,2p;7,8p;10,19p'
inode: 24
Not Allocated
Flags: Extents, 
size: 313

Inode Times:
Accessed:	2026-10-07 21:05:18.000000000 (-03)
File Modified:	2026-10-07 21:05:18.000000000 (-03)
Inode Modified:	2026-10-07 21:05:18.000000000 (-03)
File Created:	2026-10-07 21:05:18.000000000 (-03)
Deleted:	2026-10-07 21:05:18 (-03)

Direct Blocks:
1561 
```

`Not Allocated`: the inode is free, so a new file may reuse it at any moment. `size: 313`. Five times, with the
last one, `Deleted`, set when the file was removed. And at the end, **`Direct Blocks: 1561`**: the inode still
says where the data is. On ext4 that is not guaranteed. When the kernel deletes a file, it usually clears the
block list in the inode, and recovery then means searching the free space for the content, which is called
**carving**. `debugfs` deleted this one without clearing it, which is the easy case, and a good one to learn on.

`icat` reads the content an inode points to, allocated or not, and writes it out:

```
root@soc:~/case# icat work.dd 24 > recovered-contacts.csv
root@soc:~/case# cat recovered-contacts.csv
client,contact,email
acme-logistica,Gustavo Alves,gustavo@acme-logistica.example
bento-advogados,Caio Prado,caio@bento-advogados.example
casa-verde,Fabiana Reis,fabiana@casa-verde.example
delta-engenharia,Denise Rocha,denise@delta-engenharia.example
estrela-saude,Fabiana Reis,fabiana@estrela-saude.example
root@soc:~/case# sha256sum recovered-contacts.csv
c09cf34009ad7edafeb846e9f6a43df1076ed79371520d2f90cf8d9d2f7428fe  recovered-contacts.csv
```

The export of contacts is back: five client companies, a contact at each, and an e-mail address. **That is
personal data**, and it is the kind of finding lesson 21 is about. The hash of the recovered file goes into the
record beside the image's, with the inode it came from, so that anybody can recover it again from the image and
get the same file.

What recovery does not say is **who** deleted the file, or **why**. The file system recorded when; the answer to
who is in the server's logs or with its users, and in the lab it was you, playing a member of staff tidying up.
A finding states what the evidence shows and stops there.
