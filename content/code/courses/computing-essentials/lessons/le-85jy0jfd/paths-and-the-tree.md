---
title: The tree, and why a path is the only real name a file has
version: 1
---

A computer's storage is arranged as a **tree**: one root, folders inside folders, and files at
the ends of the branches. Every file sits in exactly one place on that tree, and the line from
the root down to it is called its **path**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A folder tree drawn as an indented list joined by lines. From the root, a folder called home, inside it a folder called ana marked as where you are standing, inside that a folder called documents holding a file called taxes-2025.pdf, and beside them a downloads folder and an etc folder that are not on the path. To the right the same file is written two ways: the full path from the root, and the shorter path from where you are standing.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">One file, one place, and two ways of saying where</text><path d=\"M54 60 L54 82 L64 82\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M82 90 L82 112 L92 112\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M110 120 L110 142 L120 142\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M138 150 L138 172 L148 172\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M110 120 L110 202 L120 202\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M54 60 L54 232 L64 232\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"40\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">/</text><text x=\"68\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">home/</text><text x=\"96\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">ana/</text><text x=\"124\" y=\"142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">documents/</text><text x=\"152\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">taxes-2025.pdf</text><text x=\"124\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">downloads/</text><text x=\"68\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">etc/</text><path d=\"M168 112 L186 112 M180 107 L186 112 L180 117\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"194\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">you are here</text><text x=\"380\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same file, named twice</text><text x=\"380\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">from the root</text><text x=\"380\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/home/ana/documents/taxes-2025.pdf</text><text x=\"380\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">from where you are standing</text><text x=\"380\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">documents/taxes-2025.pdf</text><path d=\"M380 204 L700 204\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"380\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">One leading slash is the whole difference.</text><text x=\"380\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Without it the name means nothing</text><text x=\"380\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">until you say where you are standing.</text><text x=\"24\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Every other way of reaching a file — a shortcut, a recent list, a search result — is a nickname for this.</text></svg>", "caption": "A path is the file's address. A shortcut is somebody's note about where the address used to be."}
```

## Absolute and relative

A path that starts at the root is **absolute**: it means the same thing typed anywhere, by
anybody, at any time. A path that does not is **relative**, and it means something only once you
know where you are standing.

Both are useful and they fail differently. An absolute path breaks when the file moves; a
relative path breaks when *you* move. A link inside a document to `images/diagram.png` keeps
working when the whole folder is copied somewhere else, and the absolute version does not — which
is why relative paths are what documents and web pages use.

Two shorthands appear everywhere and are worth knowing:

- **`.`** means *here*, the folder you are in.
- **`..`** means *the folder above this one*. So `../downloads` is a sibling of where you are.

## Windows and everything else

They draw the same tree with different punctuation, and one real difference underneath.

| | Windows | macOS and Linux |
|---|---|---|
| separator | `\` backslash | `/` forward slash |
| the top | one tree per drive: `C:\`, `D:\` | one tree, `/`, with drives attached inside it |
| the home folder | `C:\Users\ana` | `/home/ana` or `/Users/ana` |
| case in names | `Report.pdf` and `report.pdf` are the same file | they are two files |

**The last row is the one that bites.** A project that works on one machine and fails on another
with *file not found*, where the file is plainly there, is almost always a capital letter. This
is also why anything destined for a web server is written in lower case by habit.

The drive-letter difference matters less than it looks. Windows can mount a drive into a folder
too; it is just not the default.

## What a folder actually is

A folder is not a container in the way a box is. It is **a file that holds a list of names and
where each one is on the disk.** That is why moving a file inside the same drive is instant
regardless of size — nothing moves, one list loses an entry and another gains one — and why
moving it to a different drive takes as long as copying.

It also explains something people find odd: **a file can be open and being read while its name is
being changed**, because the name and the contents are two different things in two different
places.
