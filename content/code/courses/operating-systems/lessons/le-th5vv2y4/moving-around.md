---
title: Moving around: where, what, go
version: 1
---

Three commands do almost all of it: **`pwd`** says where you are, `ls` lists what is there, and
`cd` goes somewhere else.

```
ana@server:~$ pwd
/home/ana
ana@server:~$ ls
downloads  office  upgrade.log
ana@server:~$ cd office
ana@server:~/office$ ls
 clients  'invoices 2026'   notes.txt   scans
ana@server:~/office$ cd clients
ana@server:~/office/clients$ pwd
/home/ana/office/clients
ana@server:~/office/clients$ cd ..
ana@server:~/office$ cd /etc
ana@server:/etc$ pwd
/etc
ana@server:/etc$ cd -
/home/ana/office
ana@server:~/office$ cd ~
ana@server:~$ pwd
/home/ana
```

Everything else in that transcript is about **paths**, and there are two kinds:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A tree: slash at the top, holding etc and home; home holds ana; ana holds office; office holds clients, invoices 2026 and scans. You are in office. Four commands: cd clients goes down into clients, relative to where you are; cd .. goes up to /home/ana; cd /etc starts from the top and works from anywhere, because it is absolute; cd ~ goes home from anywhere.\"><defs><marker id=\"pa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60.0 44 L65.0 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 44 L170.0 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170.0 88 L165.0 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M165.0 132 L175.0 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M175.0 176 L100.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M175.0 176 L215.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M175.0 176 L310.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"40\" y=\"20\" width=\"40\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60.0\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/</text><rect x=\"40\" y=\"64\" width=\"50\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etc</text><rect x=\"140\" y=\"64\" width=\"60\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">home</text><rect x=\"140\" y=\"108\" width=\"50\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ana</text><rect x=\"140\" y=\"152\" width=\"70\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"175.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">office</text><rect x=\"60\" y=\"206\" width=\"80\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">clients</text><rect x=\"160\" y=\"206\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">invoices 2026</text><rect x=\"280\" y=\"206\" width=\"60\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scans</text><text x=\"222\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">you are here</text><text x=\"420\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">relative: starts where you are</text><text x=\"420\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd clients</text><text x=\"520\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">down into clients</text><text x=\"420\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd ..</text><text x=\"520\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">up to /home/ana</text><text x=\"420\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">absolute: starts at /</text><text x=\"420\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd /etc</text><text x=\"520\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from the top, anywhere</text><text x=\"420\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd ~</text><text x=\"520\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">home, from anywhere</text></svg>", "caption": "An absolute path works from anywhere and says so by starting with /. A relative one is shorter and means something different in every folder."}
```

- **Absolute** paths start with `/`, the top of lesson 3's tree, and mean the same thing wherever you
  are. `cd /etc` worked from the home folder and would work from anywhere.
- **Relative** paths start from where you are. `cd clients` worked because `office` holds a folder
  called `clients`; typed anywhere else, it fails.
- Three shorthands: `..` is the folder above, `~` is your home, and **`cd -`** goes back to
  the previous folder and prints where that was.

## Asking ls for more

`ls` alone shows names. **Options**, the letters after a dash, change what it shows:

```
ana@server:~$ ls -l office
total 16
drwxrwxr-x 2 ana ana 4096 Sep  1 09:00 clients
drwxrwxr-x 2 ana ana 4096 Sep  1 09:00 invoices 2026
-rw-rw-r-- 1 ana ana   25 Sep  1 09:00 notes.txt
drwxrwxr-x 2 ana ana 4096 Sep  1 09:00 scans
ana@server:~$ ls -a office
.
..
.backup-settings
clients
invoices 2026
notes.txt
scans
ana@server:~$ ls -lh office/"invoices 2026"
total 48K
-rw-rw-r-- 1 ana ana 48K Sep  1 09:00 march.pdf
```

- **`-l`**, *long*, adds a line per entry: permissions (lesson 9), owner, size in bytes, date. A `d`
  at the start of the line is a directory.
- **`-a`**, *all*, includes the names starting with a dot, which `ls` hides. `.backup-settings` was
  there all along. `.` is the folder itself and `..` the one above, the same `..` as `cd ..`.
- **`-h`**, *human*, writes sizes as `48K` instead of a byte count. It matters only where sizes are
  shown, as with `-l`.

Options combine, `-lh` or `-la`, and the order does not matter.
