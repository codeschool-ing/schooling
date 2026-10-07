---
title: Using the map to decide what comes next
version: 1
---

An inventory earns its keep by showing what is missing. `--gaps` prints only the entries with no
control:

```
ana@lab:~/guard$ guard surface --gaps
entry point     goes to  trusted?           controls
uploaded-files  prompt   no                 NONE
10 entry points, 1 with no control
```

One entry. Clients can attach briefs and files to a job, and the assistant reads them to answer
questions about the job. That text is untrusted, it reaches the prompt, and nothing in this lab checks
it. **A gap on the map is a decision waiting to be made**, and there are only three honest outcomes:

- **add a control**, and write its name in the row;
- **narrow the feature** until the existing controls cover it, such as reading only the attachment's
  title and size and never its contents;
- **accept the risk in writing**, with who accepted it, why, and the date to look again.

What is not an outcome is leaving the row empty and hoping. Text that reaches the model inside files and pages belongs to exactly this row.

## Ranking the work

Not every gap is equally urgent, and the inventory has what is needed to rank them. Two questions:

1. **What can the text reach?** Text that reaches the tools outranks text that reaches only a reply,
   which outranks text that reaches only a log.
2. **Who can write it?** Text any anonymous visitor can write outranks text only a verified customer
   can, which outranks text only staff can.

The attached files score high on both: anybody who opens an account can attach one, and the assistant
that reads it can propose tool calls. Even with lesson 10's gate in front of the tools, that combination
puts the row at the top of the list.

## The map ages

The inventory is true on the day it was written. A new tool, a new data source or a new provider
changes it, and a map that is not updated becomes a map of an application that no longer exists.
Tarefa keeps `data/surface.json` in the same repository as the code, changed in the same pull request
as the feature that changes the surface, so that a reviewer reading the code reads the row as well.
