---
title: Reading a permission string
version: 1
---

Every file and folder on Linux has **an owner, a group, and three sets of permissions**. `ls -l` shows
all of it:

```
ana@server:/srv/office$ ls -l
total 8
-rw-r--r-- 1 ana ana    9 Sep  1 09:00 payroll.txt
drwxr-xr-x 2 ana ana 4096 Sep  1 09:00 reports
ana@server:/srv/office$ id
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
ana@server:/srv/office$ id bruno
uid=1001(bruno) gid=1001(bruno) groups=1001(bruno)
ana@server:/srv/office$ ls -ld /home/ana /home/bruno
drwxr-x--- 6 ana   ana   4096 Sep 25 10:49 /home/ana
drwxr-x--- 2 bruno bruno 4096 Sep 25 10:53 /home/bruno
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"The permission string of ls -l, -rw-r-----, taken apart. The first character is the type: a dash for a file, d for a folder. Then three groups of three letters. rw- is what the owner, ana, may do: read and write. r-- is what the group, also called ana, may do: read. --- is what everybody else may do: nothing. After the string, ls -l shows the owner, ana, the group, ana, and the name, payroll.txt.\"><defs><marker id=\"mo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"34\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"37.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">-</text><text x=\"37.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">type</text><text x=\"37.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">d = folder</text><rect x=\"60\" y=\"20\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"92.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">rw-</text><text x=\"92.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">owner</text><text x=\"92.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana</text><rect x=\"130\" y=\"20\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"162.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">r--</text><text x=\"162.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">group</text><text x=\"162.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana</text><rect x=\"200\" y=\"20\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"232.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">---</text><text x=\"232.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">others</text><text x=\"232.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">everybody else</text><rect x=\"310\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"358\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ana</text><text x=\"358\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">owner</text><rect x=\"420\" y=\"20\" width=\"96\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ana</text><text x=\"468\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">group</text><rect x=\"530\" y=\"20\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">payroll.txt</text><text x=\"595\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">name</text><text x=\"20\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">r = read · w = write · x = run a file or enter a folder</text></svg>", "caption": "Three questions, three answers each: may this person read it, change it, run it or enter it? The letters answer yes, a dash answers no."}
```

- **The owner** is the user who created the file, here `ana`. The first three letters are hers.
- **The group** is one group of users, here also called `ana`: Ubuntu gives every user a private group
  of the same name. The middle three letters apply to its members.
- **Others** is everybody else on the machine, and the last three letters are theirs. `bruno`, created
  for this lesson, belongs to none of ana's groups, as `id bruno` shows, so for him the last three
  letters are the whole answer.

**`payroll.txt` starts as `-rw-r--r--`**: ana may read and write it, and everybody else may read it.
That last `r` is the reason the intern could open it.

The last command is worth noticing. **Home folders on Ubuntu are `drwxr-x---`**: others have no
permissions at all, so nobody else can even look inside `/home/ana`. That is the default since Ubuntu
21.04; older installations and many other distributions leave homes readable by everybody.
