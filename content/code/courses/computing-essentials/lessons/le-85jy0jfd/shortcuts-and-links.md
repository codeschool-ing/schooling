---
title: Shortcuts, which are notes about where something was
version: 1
---

A shortcut is a tiny file whose entire content is **a path to another file**. Double-clicking it
reads the path and opens whatever is there.

That sentence explains every strange thing shortcuts do. It is a note saying *the thing is over
there*, and a note does not know when the thing moves.

## The three kinds, and they behave differently

| | what it is | when the target moves |
|---|---|---|
| **Windows shortcut** (`.lnk`) | a file holding a path, plus an icon and arguments | usually broken. Windows sometimes guesses |
| **symbolic link** | a filesystem entry holding a path | broken, silently |
| **hard link** | a second name for the same contents | keeps working. It was never pointing |

The third one is the odd and interesting one. A **hard link** is not a pointer to a file — it *is*
a file, a second name in a second folder for exactly the same bytes. Delete one name and the other
still opens. The contents disappear only when the last name is gone.

An **alias** on macOS is the middle ground: it stores a path *and* an internal identifier, so it
survives the target being moved or renamed, which neither of the others manages.

## The failures, and what each one looks like

- **Copying a shortcut to a USB stick copies the note, not the file.** The stick now holds a
  4-kilobyte file pointing at a path that does not exist on any other machine. This is the
  commonest version of *I brought the presentation and it will not open*.
- **A backup of a folder full of shortcuts backs up nothing.** Same reason, higher stakes.
- **Moving the target breaks the shortcut**, and the error names the old path, which is genuinely
  useful — it tells you where the file used to be.
- **A shortcut can be renamed freely.** The name on the shortcut and the name of the file have
  nothing to do with each other, which is occasionally convenient and reliably confusing.

## Where they are genuinely the right answer

- **The same file needed in two structures** — a document that belongs in both `2026/invoices`
  and `clients/tavares`. One file, one place, two ways in.
- **A long path used daily.** A shortcut on the desktop to a folder six levels down.
- **A big folder that lives on the second drive** while the program expects it in the home
  folder. A symbolic link makes the program see it where it wants.

The rule that covers the failures: **a shortcut is for reaching something, never for storing it.**
If what you are doing is moving or keeping the file, the shortcut is the wrong object.

## And the one to recognise

A shortcut can point at a program and carry **arguments**, which means a `.lnk` file can be
innocent-looking and run something arbitrary. Its icon is whatever its maker chose.

That is the same shape as the extension trick: the thing you see is not the thing that runs. Both
are why an attachment that arrives unexpectedly gets looked at before it gets opened.
