---
title: The document is not a file, and everything follows from that
version: 1
---

A Word document is an object on a disk. A Google Doc is **something on a server that you are
looking at through a browser**, and the browser is a window rather than a program holding a copy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 274\" role=\"img\" aria-label=\"Two panels comparing where a document is. The left one, a file on a disk, is addressed by a path, saved by pressing save, undone by the undo stack, and shared by attaching a copy. The right one, a document on a server, is addressed by a URL, saved on every keystroke, undone from a full version history, and shared by giving somebody the same address.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Where the document is, and everything that follows from it</text><rect x=\"24\" y=\"36\" width=\"322\" height=\"196\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a file on a disk</text><text x=\"44\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its address</text><text x=\"326\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">a path</text><text x=\"44\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">saving</text><text x=\"326\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">you press save</text><text x=\"44\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">undo</text><text x=\"326\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">this session</text><text x=\"44\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sharing</text><text x=\"326\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">attach a copy</text><rect x=\"374\" y=\"36\" width=\"322\" height=\"196\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a document on a server</text><text x=\"394\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">its address</text><text x=\"676\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">a URL</text><text x=\"394\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">saving</text><text x=\"676\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">every keystroke</text><text x=\"394\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">undo</text><text x=\"676\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">every version</text><text x=\"394\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sharing</text><text x=\"676\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">the same address</text><text x=\"24\" y=\"256\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">One column is a thing you hold. The other is a thing you are looking at.</text></svg>", "caption": "Every difference in this lesson is a consequence of the first row, and the last row is where the mistakes happen."}
```

## There is no save, and the consequences of that

Every keystroke is sent as you make it. There is no save button, no *unsaved changes* warning and
no way to close without keeping what you did.

**That removes one whole category of loss and creates another.** You cannot lose an afternoon to a
crash, and you also cannot decide, an hour in, that today's work was a mistake and close without
saving.

The replacement for that decision is **version history** — *File, Version history, See version
history* — which keeps every state the document has been in, named by time and by who was editing.
It is better than the thing it replaces: you can name a version, restore one, and see exactly
which person wrote which sentence.

Two things about it are worth knowing before you need them:

- **It is not infinite on a personal account.** Old detailed versions are consolidated; the named
  ones are kept.
- **A document in the bin still exists for thirty days**, and a document deleted by its owner
  disappears for everybody it was shared with — which is the failure mode of relying on somebody
  else's document.

## Offline, which works and needs arranging first

Enabling offline access downloads a copy of the documents you have opened recently into the
browser, and edits made without a connection are sent when there is one.

It has to be turned on **before** you need it, in Drive's settings, and it works in Chrome and
Edge and not in every browser. Arranging it on the plane is not possible, which is the whole
reason to arrange it now.

## The two things that are genuinely gone

**You do not have a copy.** The document exists where the company keeps it, under an account that
can be suspended, on a service that can change. Lesson eight's argument applies exactly: a copy
you do not hold is not a backup, and the answer is the export at the end of this lesson.

**There is no file to attach.** Sending a Google Doc means either sending a link — which requires
a decision about who may open it — or exporting a copy, which is a snapshot that stops being the
document the moment somebody edits.

That second point is the source of most confusion in mixed offices, and the next section is
about the decision it forces.
