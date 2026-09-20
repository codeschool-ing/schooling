---
title: The extension is a hint, and the hint can lie
version: 1
---

The letters after the last dot in a file's name are its **extension**, and the operating system
uses them to decide which program opens the file and which icon to draw.

That is the whole of the mechanism, and the important half is what it is **not**: the extension
is not the file's type. It is a label written in the name, it can be changed by anybody with the
right to rename the file, and changing it converts nothing.

Rename `photo.jpg` to `photo.txt` and you have a text editor showing you gibberish. Rename it
back and it is a photograph again. Nothing about the bytes moved.

## The trick that follows from that

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two boxes. The upper one is labelled as what the file manager shows and reads invoice.pdf, described as a document. The lower one is labelled as what the name actually is and reads invoice.pdf.exe, with the dot e x e picked out in a different colour and described as the only part that decides what opening it does.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same file, shown and named</text><rect x=\"24\" y=\"52\" width=\"672\" height=\"68\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the file manager shows you</text><text x=\"44\" y=\"98\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">invoice.pdf</text><text x=\"676\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and it draws a document icon beside it</text><rect x=\"24\" y=\"140\" width=\"672\" height=\"68\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"44\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the name actually is</text><text x=\"44\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">invoice.pdf</text><text x=\"130\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">.exe</text><text x=\"676\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">and this is the only part that decides</text><text x=\"24\" y=\"244\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Hiding the last extension is the default on Windows, and that default is the whole of the trick.</text></svg>", "caption": "Nothing was faked. The name was always this; one setting decided how much of it you were shown."}
```

Windows hides the extension of known types by default, so a file named `invoice.pdf.exe` is
displayed as `invoice.pdf`. The icon can be set to a document by whoever made it. Everything a
person can see says *document* and the last three letters say *program*.

**Turn extension hiding off.** It is one checkbox — *File name extensions* in Explorer's View
menu — and it is the single most useful security setting on a home machine, because it makes the
whole class of attack visible instead of invisible.

Two related things worth knowing:

- **A `.zip` that contains one `.exe`** is the common delivery, because the extension is hidden
  inside the archive too until it is extracted.
- **The icon is part of the file**, chosen by whoever built it. An icon proves nothing at all.

## What the extension is good for

Almost everything, almost all of the time. It is a convention that works because people mostly do
not lie, and the alternatives are worse: macOS and Linux can inspect the first few bytes of a file
to guess its real type, which is more honest and slower, and both still use the extension as the
first answer.

| | what it means |
|---|---|
| `.pdf`, `.docx`, `.xlsx` | documents. The last two are zip archives full of XML |
| `.jpg`, `.png`, `.webp` | pictures. `.png` keeps edges sharp, `.jpg` keeps photographs small |
| `.mp4`, `.mkv` | video *containers*, which say nothing about what codec is inside |
| `.zip`, `.7z`, `.tar.gz` | archives. Several files in one |
| `.exe`, `.msi`, `.bat`, `.cmd` | things that run. Treat all four the same way |
| `.txt`, `.csv`, `.json`, `.md` | plain text, readable in any editor |

## The rules for a name that never causes trouble

- **No `\ / : * ? " < > |`.** Windows forbids them because they mean something to the system.
- **Spaces are legal and mildly annoying.** They work everywhere and they need quoting whenever a
  name reaches a command line. A hyphen or an underscore never needs quoting.
- **Accents and `ç` are fine now** and were not ten years ago. The one place they still cause
  trouble is a file travelling to a very old system or a badly written server.
- **Keep it short enough to read.** Windows has a path limit around 260 characters that still
  surfaces in odd places, and it counts the folders too.
- **Never end a name with a space or a dot.** Windows silently removes them, which means a file
  you create is not the file you named.
