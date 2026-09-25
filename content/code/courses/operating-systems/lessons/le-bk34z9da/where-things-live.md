---
title: Where everything lives: one tree, no letters
version: 1
---

The first surprise for somebody coming from Windows is that there is no `C:`. Linux has **one tree of
folders**, starting at `/`, the **root**, and every disk, stick and network share appears somewhere
inside it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two ways of organising disks. On Linux, one tree starting at slash: home slash ana holds your files, etc holds configuration, var slash log holds logs, usr holds programs, and a USB stick appears as a folder, media slash usb, once mounted. On Windows, a separate tree per drive: C: is the system disk, with Users slash Ana for your files, Windows for the system and Program Files for programs; a USB stick gets its own letter, E:.\"><defs><marker id=\"tr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Linux: one tree</text><text x=\"380\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Windows: a tree per drive</text><rect x=\"20\" y=\"34\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">/</text><path d=\"M40 60 L40 80 L60 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">home/ana</text><text x=\"170\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your files</text><path d=\"M40 60 L40 114 L60 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etc</text><text x=\"170\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">configuration</text><path d=\"M40 60 L40 148 L60 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">var/log</text><text x=\"170\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">logs</text><path d=\"M40 60 L40 182 L60 182\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">usr</text><text x=\"170\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programs</text><path d=\"M40 60 L40 216 L60 216\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"66\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">media/usb</text><text x=\"170\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a USB stick, mounted</text><rect x=\"380\" y=\"34\" width=\"44\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"402\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C:\\</text><text x=\"432\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the system disk</text><path d=\"M402 60 L402 80 L422 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"428\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Users\\Ana</text><text x=\"560\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your files</text><path d=\"M402 60 L402 114 L422 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"428\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Windows</text><text x=\"560\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the system</text><path d=\"M402 60 L402 148 L422 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"428\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Program Files</text><text x=\"560\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programs</text><rect x=\"380\" y=\"196\" width=\"44\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"402\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">E:\\</text><text x=\"432\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a USB stick, its own letter</text></svg>", "caption": "A second disk on Linux is a folder somewhere in the one tree. On Windows it is a new letter."}
```

Here is the top of that tree on the freshly installed server:

```
ana@server:~$ ls /
bin                dev   lib                media  proc  sbin                sys  var
bin.usr-is-merged  etc   lib.usr-is-merged  mnt    root  sbin.usr-is-merged  tmp
boot               home  lib64              opt    run   srv                 usr
ana@server:~$ ls /home
ana
```

You will rarely need most of these, and a handful are worth recognising from the start:

| folder | holds | the Windows equivalent |
|---|---|---|
| `/home/ana` | Ana's own files and settings | `C:\Users\Ana` |
| `/etc` | the system's configuration, as text files | the registry, lesson 15 |
| `/var/log` | logs | the Event Viewer, lesson 17 |
| `/usr` | installed programs | `C:\Program Files` |
| `/tmp` | temporary files, emptied at restart | `%TEMP%` |
| `/media`, `/mnt` | where extra disks and sticks appear | the other drive letters |
| `/boot` | the kernel and GRUB's files | the EFI and system partitions |

The names ending in `.usr-is-merged` are leftovers of a recent Ubuntu change and can be ignored.

## Mounting

Attaching a disk to a folder in the tree is called **mounting** it. Plug in a USB stick on the desktop
version and it appears under `/media/ana/`, the name of the stick after it. On the server, nothing is
mounted automatically; lesson 12 does it by hand. The principle is the one in the figure: on Linux a
second disk is a **folder**, on Windows it is a **letter**, and in both cases the files are the same.

## Upper and lower case

One more difference that trips people up: on Linux, `Report.txt` and `report.txt` are **two different
files** in the same folder. On Windows and, by default, on macOS they are the same file. A document that
opens fine on a Windows PC and "cannot be found" when a Linux server looks for it is very often this.
