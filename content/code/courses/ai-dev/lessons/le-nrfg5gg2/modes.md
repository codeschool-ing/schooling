---
title: Completion, chat and agent
version: 1
---

Editor assistants come in three modes, and the useful way to tell them apart is not what they can
do but **how much they do before you look**. Each step up hands over more of the work, and moves
your part from writing code to reviewing it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three modes of an editor assistant, from less to more autonomy. Completion: you review a line or a block as it appears. Chat: you review a reply or a diff before applying it. Agent: it edits files and runs commands, and you review the whole change like a pull request.\"><defs><marker id=\"md-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"150\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">completion</text><text x=\"135.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">suggests at the cursor</text><text x=\"135.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">you review: a line or a block</text><rect x=\"255\" y=\"100\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chat</text><text x=\"360.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answers, proposes</text><text x=\"360.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">you review: a reply or a diff</text><rect x=\"480\" y=\"50\" width=\"210\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">agent</text><text x=\"585.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">edits files, runs commands</text><text x=\"585.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">you review: the whole change</text><path d=\"M40 236 L680 236\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#md-ah)\"></path><text x=\"360\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what it does before you look</text></svg>", "caption": "Each step up does more before you look, and the review moves from a line to a pull request."}
```

## Inline completion

The ghost text that appears as you type, accepted with a key. It is the mode of lesson 3 sections
02 and 04: a fill-in-the-middle request built from the file around the cursor, sent after a pause
in your typing, many times a minute. **Its unit of review is a line or a block**, small enough that
you read it as it appears, and it is the mode where a mistake is cheapest to catch because you
are looking at the exact place it lands.

What it is bad at is anything that needs a decision outside the current file. It sees the context
the editor gathered, and that is all.

## Chat

A panel where you ask questions and get answers, code and diffs, as in lesson 3 sections 06 and
07. You choose the context (the selection, the open files, the files you name), and **nothing
changes in the project until you apply it**. The unit of review is a reply, and the habit that
matters is the one from lesson 3 section 06: ask for a diff, read it as a change.

Chat is also where an assistant is most useful without writing anything: explaining an unfamiliar
module, reading a stack trace with you, listing the cases a function does not handle. An answer to
a question is easier to check than code is.

## Agent

The assistant plans, opens files, edits several of them and **runs commands**: the tests, the
linter, a script, `git`. It works in a loop of the kind lesson 7 builds, and it can take many steps
before it comes back to you. The unit of review is the whole change, the way a pull request is.

Two things make agent mode safe enough to use, and both are settings you choose:

- **Permissions.** Whether each file edit and each command needs your approval, or only some, or
  none. Approving every command is slow and is the right default in a project you do not know.
  "Allow the test command without asking" is a reasonable step. "Allow any command" lets text the
  agent read decide what runs on your machine, which lesson 11 shows is a real risk.
- **A place to undo from.** Work on a branch, commit before you start, and review with `git diff`
  when it finishes. An agent that edited twelve files is reviewed like a colleague's pull request
  of twelve files: slowly, with the tests running.

## Choosing

Use the smallest mode that does the job. A missing line is a completion. A question about the code
is a chat. A change across files with a clear way to check it (the tests must pass, the linter
must be clean) is where an agent saves real time. The more a mode does on its own, the more the
outcome depends on that check existing before you start.
