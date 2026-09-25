---
title: Text or objects: the difference that matters
version: 1
---

Both shells connect commands with a **pipe**, `|`: the output of one becomes the input of the next.
What travels down the pipe is where they differ.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"Two pipes compared. In bash, text goes down the pipe: ls -l prints lines such as -rw-rw-r-- 1 ana ana 25 Sep 1 09:00 acme.txt, and a command that wants the size has to find the fifth word. In PowerShell, objects go down the pipe: each file is an object with properties, Name acme.txt and Length 25 among them, and a command that wants the size asks for the Length property.\"><defs><marker id=\"ob-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">bash: text goes down the pipe</text><text x=\"380\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PowerShell: objects go down the pipe</text><rect x=\"20\" y=\"34\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\" xml:space=\"preserve\">-rw-rw-r-- 1 ana ana 25 Sep  1 09:00 acme.txt</text><rect x=\"20\" y=\"74\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\" xml:space=\"preserve\">-rw-rw-r-- 1 ana ana 15 Sep  1 09:00 bravo.txt</text><text x=\"20\" y=\"134\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the size is &quot;the fifth word&quot;</text><rect x=\"380\" y=\"34\" width=\"156\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Name</text><text x=\"470\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">acme.txt</text><text x=\"390\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Length</text><text x=\"470\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">25</text><rect x=\"550\" y=\"34\" width=\"156\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Name</text><text x=\"640\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bravo.txt</text><text x=\"560\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Length</text><text x=\"640\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">15</text><text x=\"380\" y=\"134\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the size is .Length</text></svg>", "caption": "Neither is better everywhere. Text works with every program ever written; objects make the next command independent of how the last one laid out its columns."}
```

```
ana@server:~$ ls -l office/clients
total 8
-rw-rw-r-- 1 ana ana 25 Sep  1 09:00 acme.txt
-rw-rw-r-- 1 ana ana 15 Sep  1 09:00 bravo.txt
PS /home/ana> Get-ChildItem office/clients | Select-Object Name, Length, LastWriteTime

Name      Length LastWriteTime
----      ------ -------------
acme.txt      25 09/01/2026 09:00:00
bravo.txt     15 09/01/2026 09:00:00

PS /home/ana> Get-ChildItem office/clients | Where-Object Length -gt 20

    Directory: /home/ana/office/clients

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
-rw-rw-r--        ana ana        09/01/2026 09:00           25 acme.txt
```

- **bash passes text.** `ls -l` prints lines, and a command that wants the size has to know it is the
  fifth word on each line. Lesson 12 does exactly that, and it works because the format of `ls -l`
  has barely changed in fifty years.
- **PowerShell passes objects.** `Get-ChildItem` sends file objects, and `Select-Object` picks
  properties **by name**, `Name`, `Length`, `LastWriteTime`, whatever column they would have been
  printed in. `Where-Object Length -gt 20` kept only the files larger than 20 bytes, `acme.txt`,
  without anybody counting columns.

The consequence for support work: **a PowerShell one-liner keeps working** when a Windows update
changes how a table is laid out, because it never read the table. A bash one-liner is **shorter, and
works with every program**, including ones written in 1985 that know nothing about objects.

## Three habits for any shell

- **Tab** completes names, section 03's safety check.
- **The up arrow** brings back the previous command, and **Ctrl+R** searches all of them.
- **Ctrl+C** stops a command that is running, and it is what to press when something scrolls forever.

The shell keeps the list, and it can show it:

```
ana@server:~$ cd office
ana@server:~/office$ ls
 clients  'invoices 2026'   notes.txt   scans
ana@server:~/office$ cd clients
ana@server:~/office/clients$ history
    1  cd office
    2  ls
    3  cd clients
    4  history
```

A numbered record of what you typed is also what makes the command line **repeatable**: the steps that
fixed one machine can be copied, checked and run on the next.
