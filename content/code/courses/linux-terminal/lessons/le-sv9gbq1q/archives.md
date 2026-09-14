---
title: Archives: `tar`, `gzip`, `zip`
version: 1
---

`tar -xzvf` is the most-copied incantation on the internet and one of the least understood. It is
four letters, each with a job, and once you can read them you never need to look it up again.

**The first thing to know is that archiving and compressing are two separate operations.**

| | does | produces |
|---|---|---|
| `tar` | puts many files into one, keeping names, permissions and dates | `.tar` — **not smaller** |
| `gzip`, `bzip2`, `xz` | make **one file** smaller | `.gz`, `.bz2`, `.xz` |
| `zip` | both at once | `.zip` |

That is why `.tar.gz` has two extensions: it is a tar archive that was then gzipped. It is also
why plain `gzip` cannot take a directory — it compresses one file, and `tar` is what turns a
directory into one file.

## Reading the letters

```
tar -czf project.tar.gz src notes
tar -xzf project.tar.gz
tar -tzf project.tar.gz
```

| letter | means | note |
|---|---|---|
| `c` | **create** | pick exactly one of c, x, t |
| `x` | e**x**tract | |
| `t` | lis**t** | |
| `z` | gzip | `j` for bzip2, `J` for xz |
| `f` | **file**, and its name comes next | **`f` must be last** — it eats the next word |
| `v` | verbose: print each name | optional, and noisy on a big archive |

**`f` last** is the one rule that matters, because `tar -cfz` silently tries to create an archive
named `z`. Everything else is free order.

Modern `tar` also detects the compression by itself, so `tar -xf project.tar.gz` works without the
`z`. Type it anyway — it is what every example you copy will have, and it costs nothing.

## Creating and listing

```
ana@vm:~/ar$ tar -cf project.tar src notes
ana@vm:~/ar$ tar -tvf project.tar
drwxr-xr-x ana/ana           0 2026-09-14 22:29 src/
-rw-r--r-- ana/ana          29 2026-09-14 22:29 src/util.h
-rw-r--r-- ana/ana          65 2026-09-14 22:29 src/util.c
-rw-r--r-- ana/ana         194 2026-09-14 22:29 src/main.c
drwxr-xr-x ana/ana           0 2026-09-14 22:29 notes/
-rw-r--r-- ana/ana          20 2026-09-14 22:29 notes/draft.txt
-rw-r--r-- ana/ana          34 2026-09-14 22:29 notes/2025-01-plan.md
-rw-r--r-- ana/ana          26 2026-09-14 22:29 notes/2025-02-plan.md
```

`-t` lists, `-v` makes the listing long — and it is section 41's listing again, with the owner and
group written as `ana/ana`. **That is what `tar` preserves and `zip` does not**: permissions,
ownership, timestamps, symlinks, and the paths exactly as given.

**Always `-t` an archive before you `-x` it.** Look at that listing: the paths start at `src/` and
`notes/`, which means extracting it here scatters two directories into the current one. An archive
whose contents are not inside a single top-level directory is called a *tarbomb*, and it is a
mess to clean up — thirty loose files mixed into whatever was already there.

The defences are both free:

```
ana@vm:~/ar$ mkdir out
ana@vm:~/ar$ tar -xzf project.tar.gz -C out
ana@vm:~/ar$ ls out
notes  src
```

`-C` says *change to this directory first*. Extract into a new empty directory and a tarbomb is
harmless.

`--strip-components=1` removes leading path elements, which is how you extract
`something-1.4.2/src/...` into `src/...` without the version-numbered wrapper:

```
ana@vm:~/ar$ tar -xzf project.tar.gz -C out --strip-components=1
ana@vm:~/ar$ ls out
2025-01-plan.md  2025-02-plan.md  draft.txt  main.c  notes  src  util.c  util.h
```

That one is worth staring at, because it shows the cost too: with the first component stripped,
the contents of `src/` and `notes/` land side by side in `out`, and the two directories from the
earlier extract are still there. `--strip-components` is a sharp tool, and `-t` first tells you
whether you need it.

## Which compression

```
ana@vm:~/ar$ ls -l logs/app.log
-rw-r--r-- 1 ana ana 1405960 Sep 14 22:29 logs/app.log
ana@vm:~/ar$ tar -cf logs.tar logs
ana@vm:~/ar$ tar -czf logs.tar.gz logs
ana@vm:~/ar$ tar -cjf logs.tar.bz2 logs
ana@vm:~/ar$ tar -cJf logs.tar.xz logs
ana@vm:~/ar$ ls -lh logs.tar logs.tar.gz logs.tar.bz2 logs.tar.xz
-rw-r--r-- 1 ana ana 1.4M Sep 14 22:29 logs.tar
-rw-r--r-- 1 ana ana  44K Sep 14 22:29 logs.tar.bz2
-rw-r--r-- 1 ana ana 425K Sep 14 22:29 logs.tar.gz
-rw-r--r-- 1 ana ana  12K Sep 14 22:29 logs.tar.xz
```

Note first that **`logs.tar` is the same size as what went in.** `tar` did not compress anything;
it only packed.

Then the three that did. Those ratios are unusually good, because that file is the same block of
text repeated forty times and repetition is exactly what a compressor eats — but the *ordering* is
the real lesson and it holds everywhere:

| | typical use | speed |
|---|---|---|
| `gzip` (`z`) | **the default.** Everything can read it | fast |
| `bzip2` (`j`) | older, slower, largely superseded | slow |
| `xz` (`J`) | the smallest. Slow to make, fine to read | very slow to compress |
| `zstd` (`--zstd`) | modern: nearly gzip's speed, near xz's size | fast |

Use `gzip` unless you have a reason. Use `xz` for something written once and downloaded many
times, which is why distribution packages use it. `zstd` is the one quietly taking over, and it is
worth knowing the name when you meet a `.tar.zst`.

## `gzip` on its own compresses one file, in place

```
ana@vm:~/ar$ gzip -k notes/draft.txt
ana@vm:~/ar$ ls -l notes/draft.txt notes/draft.txt.gz
-rw-r--r-- 1 ana ana 20 Sep 14 22:29 notes/draft.txt
-rw-r--r-- 1 ana ana 50 Sep 14 22:29 notes/draft.txt.gz
```

Two things there. **`-k` keeps the original** — without it `gzip` replaces the file, which
surprises people. And the compressed file is *bigger* than the original: twenty bytes of text plus
a gzip header. Compression has a fixed cost, and on tiny files it loses.

`gzip -d` decompresses, and so does `gunzip`. It will not overwrite:

```
ana@vm:~/ar$ gzip -d notes/draft.txt.gz
gzip: notes/draft.txt already exists;   not overwritten
```

Politer than `cp` was in section 42, and for once you are being asked.

There is also `zcat`, `zless` and `zgrep`, which read a `.gz` without unpacking it first. On
`/var/log`, where yesterday's logs are already gzipped, `zgrep` is the difference between
searching the last month and searching today.

## `zip`, and when to use it

```
ana@vm:~/ar$ zip -qr project.zip src notes
ana@vm:~/ar$ unzip -l project.zip
Archive:  project.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2026-09-14 22:29   src/
       29  2026-09-14 22:29   src/util.h
       65  2026-09-14 22:29   src/util.c
      194  2026-09-14 22:29   src/main.c
        0  2026-09-14 22:29   notes/
       20  2026-09-14 22:29   notes/draft.txt
       50  2026-09-14 22:29   notes/draft.txt.gz
       34  2026-09-14 22:29   notes/2025-01-plan.md
       26  2026-09-14 22:29   notes/2025-02-plan.md
---------                     -------
      418                     9 files
```

`-r` for recursive — **`zip` needs it and `tar` does not**, which is the first thing to trip over.
`-q` for quiet. `unzip -l` lists, `unzip -d somewhere` extracts into a directory, and it is `-d`
rather than `-C` because these are two unrelated programs that happened to solve the same problem.

**Use `zip` when the file is going to somebody on Windows or macOS**, where it opens with a
double-click. Use `tar` for everything staying on Linux, because it keeps the permissions and
ownership that a deployment or a backup depends on.

And one honest warning: `unzip` is not installed everywhere by default, and neither is `zip`.
`tar` always is.

## `file` settles any argument about what you have

```
ana@vm:~/ar$ file project.tar project.tar.gz project.tar.xz project.zip
project.tar:    POSIX tar archive (GNU)
project.tar.gz: gzip compressed data, from Unix, original size modulo 2^32 10240
project.tar.xz: XZ compressed data, checksum CRC64
project.zip:    Zip archive data, at least v1.0 to extract, compression method=store
```

Section 43 said the extension is a hint. Somebody will hand you a `.zip` that is a `.tar.gz`, or a
`.tar.gz` that was never compressed, and `file` is how you stop guessing.
