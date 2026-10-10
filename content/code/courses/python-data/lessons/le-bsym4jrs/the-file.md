---
title: What a notebook is on disk
version: 1
---

**A `.ipynb` file is JSON: a list of cells, each holding its source and the outputs it produced
the last time it ran.** It is not a script, and it is not a picture of the page either. Knowing
what is in it explains three things that otherwise look like quirks: why a notebook can be sent to
somebody who never runs it, why it is awkward in version control, and why it can carry data you
did not mean to share.

Here is the notebook from the previous section, with its five cells run once each, top to bottom:

@@capture:file-head@@

Every cell is an object with the same keys, in alphabetical order:

| key | holds |
|---|---|
| `cell_type` | `code` or `markdown` |
| `execution_count` | the number in brackets on the page, or `null` if it never ran |
| `id` | a random identifier JupyterLab gives each cell, so yours differ |
| `outputs` | what the cell produced, **saved with the notebook** |
| `source` | what you typed, one string per line |

The outputs are the interesting part. The fourth cell printed a line and then showed a value, and
the file keeps both, as two outputs of two different kinds:

@@capture:file-outputs@@

The `stream` is what `print` wrote, newline included. The `execute_result` is the value of the
last line, stored under `text/plain` as its representation. A DataFrame stores a second version of
itself under `text/html`, which is the table JupyterLab draws, and a chart stores the picture
itself, as a long string of text that decodes to a PNG. **This course shows the `text/plain`
version of every output**, which is the same text `print` would give, and on your screen the
numbers are the same and the table is drawn with lines.

At the end of the file is the notebook's own metadata:

@@capture:file-tail@@

`kernelspec` names the kernel the notebook asks for when it opens, and `language_info` records the
Python that last ran it, `3.12.3` here. Nothing in the file records **which libraries** were
installed, which is what lesson 3 adds beside it.

## What follows from it

**The file can be read without being run.** Send `first.ipynb` to somebody and they see your
results, including any number your data produced, without running a line. That is the notebook's
great strength as a document, and it is also its risk: an output that printed a customer's e-mail
address, or an access token, is saved in the file and travels with it. **Clear the outputs before
sharing a notebook that touched anything private**: Edit, Clear Outputs of All Cells, then save.

**The file records what happened, not whether it still would.** Each output is from the moment its
cell ran, and the execution counts say in what order that was. A notebook saved with counts `1, 2,
3, 4, 5` was run top to bottom once; one saved with `7, 3, 12` was not, and lesson 2 is about what
that can hide.

**Version control sees JSON.** Run one cell again and its `execution_count` changes, and so may its
output; a chart re-rendered is a new string of thousands of characters. A diff of two notebooks is
mostly noise around the one line that changed, which is part of why lesson 21 moves the work that
has to last into a script.

**The kernel's memory is not in the file.** Variables, imported modules and opened files all live
in the kernel process and vanish when it stops. Open `first.ipynb` tomorrow and the outputs are
there, but `lines` does not exist until the cell that makes it runs again.
