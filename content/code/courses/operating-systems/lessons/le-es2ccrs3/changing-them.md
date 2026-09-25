---
title: Changing permissions and owners
version: 1
---

**`chmod`** changes permissions, and it takes them two ways.

**By letter**, which changes only what you name: `u`, `g`, `o` for owner (*user*), group and others,
`+` or `-`, and the letters. It is what fixes a script that will not run:

```
ana@server:/srv/office$ cat backup.sh
#!/bin/sh
echo backup done
ana@server:/srv/office$ ls -l backup.sh
-rw-rw-r-- 1 ana ana 27 Sep 25 10:53 backup.sh
ana@server:/srv/office$ ./backup.sh
bash: ./backup.sh: Permission denied
ana@server:/srv/office$ chmod u+x backup.sh
ana@server:/srv/office$ ./backup.sh
backup done
ana@server:/srv/office$ chmod 640 payroll.txt
ana@server:/srv/office$ ls -l payroll.txt backup.sh
-rwxrw-r-- 1 ana ana 27 Sep 25 10:53 backup.sh
-rw-r----- 1 ana ana  9 Sep  1 09:00 payroll.txt
ana@server:/srv/office$ stat -c "%a %A %n" payroll.txt backup.sh
640 -rw-r----- payroll.txt
764 -rwxrw-r-- backup.sh
```

`./backup.sh` was refused because nobody had `x` on it. `chmod u+x` added it for the owner, and the same
file ran.

**By number**, which sets all nine at once. Each letter is worth a number, and each group's digit is
their sum:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"How the numbers of chmod work. Read is 4, write 2 and run or enter 1, added up for each of owner, group and others. 640 is rw-, r--, ---: six is four plus two, then four, then zero; the payroll file, which its owner edits and its group reads. 755 is rwx, r-x, r-x: seven, five, five; a program or a public folder. 2770 is rwx, rws, ---: the leading 2 is setgid, shown as an s in the group&#x27;s place; a shared folder whose new files join its group.\"><defs><marker id=\"oc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" xml:space=\"preserve\">r = 4   w = 2   x = 1</text><text x=\"200\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each letter is a number; add them per group</text><rect x=\"20\" y=\"40\" width=\"64\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">640</text><rect x=\"100\" y=\"40\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rw-</text><text x=\"140\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 = 4+2</text><rect x=\"190\" y=\"40\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r--</text><text x=\"230\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"280\" y=\"40\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">---</text><text x=\"320\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"380\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">payroll: owner edits, group reads</text><rect x=\"20\" y=\"92\" width=\"64\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">755</text><rect x=\"100\" y=\"92\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rwx</text><text x=\"140\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7 = 4+2+1</text><rect x=\"190\" y=\"92\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r-x</text><text x=\"230\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 = 4+1</text><rect x=\"280\" y=\"92\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r-x</text><text x=\"320\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"380\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a program or a public folder</text><rect x=\"20\" y=\"144\" width=\"64\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2770</text><rect x=\"100\" y=\"144\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rwx</text><text x=\"140\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><rect x=\"190\" y=\"144\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rws</text><text x=\"230\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7 + setgid</text><rect x=\"280\" y=\"144\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">---</text><text x=\"320\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"380\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a shared folder: new files join its group</text></svg>", "caption": "Three digits, one per group, each the sum of 4, 2 and 1. A fourth digit in front sets the special bits, and 2 is the one a shared folder needs."}
```

`chmod 640 payroll.txt` gave the owner read and write, the group read, and others nothing, in one
step. `stat` prints the number for a file that already exists, which is the quickest way to learn to
read them.

The numbers worth knowing by heart: `644` for an ordinary file, `600` for a private one, `755`
for a program or a folder anyone may enter, `700` for a private folder.

## Owners

```
ana@server:/srv/office$ chown bruno payroll.txt
chown: changing ownership of 'payroll.txt': Operation not permitted
ana@server:/srv/office$ sudo chown bruno:bruno payroll.txt
ana@server:/srv/office$ ls -l payroll.txt
-rw-r----- 1 bruno bruno 9 Sep  1 09:00 payroll.txt
```

**`chown` changes the owner, and only root may do it.** Otherwise anybody could give a file to
somebody else, and with it the responsibility for what is in it, or fill another user's disk quota.
`chown bruno:bruno` sets owner and group together.
