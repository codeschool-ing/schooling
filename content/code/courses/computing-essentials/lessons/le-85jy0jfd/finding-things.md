---
title: Finding things, and why search sometimes finds nothing
version: 1
---

There are two ways a computer can look for a file, and they behave so differently that knowing
which one you are using explains almost every surprise.

- **A scan** walks the tree and reads every name. It always finds what is there, and it takes as
  long as the tree is big.
- **An index** is a list built in advance — names, and often the contents of documents — that is
  consulted instead of the disk. It answers instantly and it answers about **the tree as it was
  when the index was last updated.**

Every desktop search box uses the index. So *search found nothing* almost always means **the
index has not reached that file yet**, or the folder is not one the index covers, or the index is
damaged. The file is there; the list is not.

## What to do when it finds nothing

1. **Wait.** A file created a minute ago on a busy machine may not be indexed yet.
2. **Check what is indexed.** Windows indexes the home folder and not the whole disk by default;
   an external drive is usually not indexed at all.
3. **Rebuild the index** if it is consistently wrong. It takes hours and it fixes the whole class
   of problem.
4. **Use a tool that scans**, for the cases the index will not cover — `Everything` on Windows,
   `find` on the command line, `mdfind` on macOS.

## The operators worth knowing

Search boxes take more than words, and four kinds of filter cover almost everything:

| | what it does |
|---|---|
| `"exact phrase"` | the words together and in that order |
| `type:pdf` or `kind:document` | narrows by what it is rather than what it says |
| `date:this week`, `modified:>2026-01-01` | the filter people reach for last and should reach for first |
| `size:>100MB` | the one that finds what is filling a disk |

**Date and size are the two that find a file whose name you cannot remember**, and they are the
two nobody uses. *Modified this week, larger than a megabyte, type pdf* is usually a list of four
things, one of which is the one you wanted.

## The part that is your job

An index searches names and, for documents, the text inside. It cannot search what is not
written down.

Which means the quality of your search is decided long before you search — by what the files are
called. **`document(3).pdf` is unfindable by any tool ever made.** Not because search is weak,
but because there is nothing in that name to match against.

That is the whole argument for the next section, and it is the only place in this lesson where
the work is yours rather than the machine's.

## A note about the cloud

Files synced from a cloud service are often **placeholders** — a name and an icon on your disk,
with the contents still on the server until you open them. That is called *files on demand*, and
it saves an enormous amount of space.

It also means a search of file *contents* may not reach them, a backup tool may copy the
placeholders rather than the files, and a folder that shows 40 GB may be using 40 MB. Worth
knowing before you rely on either.
