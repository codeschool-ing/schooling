---
title: The first screen
version: 1
---

A reviewer opening a repository sees the README's first screen before they decide whether to scroll.
That screen has to do three things, and loanbook's does them in twelve lines:

```
ana@laptop:~/loanbook$ head -12 README.md
# loanbook

The IT room of a secondary school lends projectors, laptops and adapters to
teachers, and the record of who had what was a paper sheet taped to the door.
loanbook replaces the sheet with one page: what is out, who has it, and when
it is due back.

![The list: four items out, one of them overdue](docs/screenshot.png)

## What it does

- Lists the equipment, and for each item on loan, who has it and until when.
```

**One paragraph that says what it is and for whom**, in the words of the problem, not the technology.
*A page that shows what is out, who has it, and when it is due back* can be understood by somebody who
has never programmed. *A Python REST API with SQLite persistence* can be understood only by somebody who
already knows what you built it for, which is nobody yet.

**A picture of it working.** A screenshot is the fastest evidence there is: before reading a line of code,
the reviewer has seen the list, the four loans and the one overdue. Its `alt` text says what it shows, for
readers who cannot see it and for the moment the image fails to load. Lesson 17 is about taking one that
shows the right thing.

**The way in**, which for loanbook is the next heading. A project with a live address puts it here, in
the second line, as a link; loanbook's lives in the lab, so its first screen says nothing about one rather
than printing an address the reader cannot open.

What is **not** on the first screen matters as much: no badges, no table of contents, no installation
steps, no history of how the idea came about. Each of them pushes the one paragraph and the picture below
the fold, where most readers never go.
