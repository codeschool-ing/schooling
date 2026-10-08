---
title: The Sleuth Kit, layer by layer
version: 1
---

**The Sleuth Kit** (TSK) is a set of command-line tools for reading disk images without mounting them, and it is
the engine underneath Autopsy, the graphical tool later in this lesson. Lesson 1 installed it with the package
`sleuthkit`. Its tools are named after the **layer** of the file system they read:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The four layers The Sleuth Kit reads, from the top: names, the file names in directories, read by fls; metadata, the inodes with sizes, times and block lists, read by istat and icat; content, the blocks of data, read by blkcat; and the file system itself, its layout, read by fsstat. A deleted file has lost its name's link to the inode, but its inode and its blocks are still there.\"><rect x=\"10\" y=\"14\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">names</text><text x=\"190\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">fls</text><text x=\"320\" y=\"41\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">exports/contacts-2026-08.csv  *</text><rect x=\"10\" y=\"70\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">metadata</text><text x=\"190\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">istat · icat</text><text x=\"320\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">inode 24: 313 bytes, block 1561</text><rect x=\"10\" y=\"126\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">content</text><text x=\"190\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">blkcat</text><text x=\"320\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">block 1561: client,contact,email…</text><rect x=\"10\" y=\"182\" width=\"700\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">file system</text><text x=\"190\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">fsstat</text><text x=\"320\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ext4, 4096-byte blocks</text></svg>", "caption": "Deleting cuts the top link. Everything under it waits to be overwritten."}
```

The bottom layer first. `fsstat` describes the file system as a whole:

```
root@soc:~/case# fsstat work.dd | head -5
FILE SYSTEM INFORMATION
--------------------------------------------
File System Type: Ext4
Volume Name: files-data
Volume ID: 812eafe98540ccb188486ecf1d6d4db5
root@soc:~/case# fsstat work.dd | grep -E '^(Block Size|Block Range|Free Blocks)'
Block Range: 0 - 8191
Block Size: 4096
Free Blocks: 6631
```

An ext4 file system called `files-data`, made of 8,192 blocks of 4,096 bytes, of which 6,631 are free. Then the
top layer: `fls` lists names, `-r` through every folder, `-p` with the full path:

```
root@soc:~/case# fls -r -p work.dd
d/d 11:	lost+found
d/d 12:	clients
d/d 13:	clients/acme-logistica
r/r 14:	clients/acme-logistica/contracts.csv
d/d 15:	clients/bento-advogados
r/r 16:	clients/bento-advogados/contracts.csv
d/d 17:	clients/casa-verde
r/r 18:	clients/casa-verde/contracts.csv
d/d 19:	clients/delta-engenharia
r/r 20:	clients/delta-engenharia/contracts.csv
d/d 21:	clients/estrela-saude
r/r 22:	clients/estrela-saude/contracts.csv
d/d 23:	exports
r/r * 24:	exports/contacts-2026-08.csv
V/V 8193:	$OrphanFiles
```

Each line is a type (`d` a directory, `r` a regular file), an **inode number**, and a name. The inode is the
record behind the name: size, owner, times, and which blocks hold the data. And one line is different: **the
asterisk in `r/r * 24`** marks a name whose inode is no longer allocated. That is a deleted file, and `fls`
found it because ext4 removed the link between the name and the inode, not the name itself.

`$OrphanFiles` is not on the disk at all: it is a folder TSK invents to hold inodes that have data but no name
left pointing at them.
