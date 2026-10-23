---
title: Mermaid: the ticket's life, as text
version: 1
---

**Mermaid is a text syntax for diagrams, rendered by a JavaScript library.** GitHub, GitLab and many
documentation sites draw a Mermaid block inside Markdown without any tool at all, which is its great
advantage: the diagram lives in the README and renders where people already read. For a file of its
own, or for a check in a pipeline, the command-line renderer `mmdc` does the same job.

## Installing the renderer

Install it in the `diagrams` folder, at a fixed version, so that every member of a team renders with
the same one:

```
ana@vm:~/diagrams$ npm install --no-audit --no-fund @mermaid-js/mermaid-cli@11.17.0

added 190 packages in 11s
```

The install also downloads the headless browser that `mmdc` uses to draw, which is where most of the
700 MB goes and most of the time.

## Lesson 4's state machine, written down

Save this as `ticket.mmd`. It is the ticket's life from lesson 4, plus the transition the state
table added:

```
stateDiagram-v2
    direction LR
    [*] --> Held
    Held --> Held : payment declined
    Held --> Paid : payment approved
    Held --> Expired : 10 min pass / release seat
    Paid --> Boarded : scanned at the door
    Paid --> Refunded : cancelled [3 h or more] / refund
    Paid --> NoShow : departed [not scanned]
    Expired --> Expired : payment approved / refund
```

Each line after the header is one transition: source, `-->`, target, and after the colon the label,
which here keeps lesson 4's `event [guard] / action` form as plain text. `[*]` is the initial
pseudostate. Mermaid draws the states and places them itself.

Render it:

```
ana@vm:~/diagrams$ npx mmdc -i ticket.mmd -o ticket.svg
Generating single mermaid chart
ana@vm:~/diagrams$ ls -l ticket.svg
-rw-rw-r-- 1 ana ana 19293 Oct 23 02:06 ticket.svg
```

Open `ticket.svg` in a browser. Compare it with the figure in lesson 4: the same states and
transitions, laid out by the tool rather than by hand.

## When the text is wrong

Change the arrow on the *Paid → Boarded* line from `-->` to `->`, save it as `broken.mmd`, and
render again:

```
ana@vm:~/diagrams$ npx mmdc -i broken.mmd -o broken.svg 2>&1 | head -5
Generating single mermaid chart

Error: Parse error on line 7:
...lease seat    Paid -> Boarded : scanned
----------------------^
ana@vm:~/diagrams$ npx mmdc -i broken.mmd -o broken.svg > /dev/null 2>&1; echo $?
1
```

The renderer refuses, names the line, points at the place and exits with a non-zero status. **That
refusal is the whole case for diagrams as text in a team**: a picture in a drawing tool cannot be
wrong in a way a machine notices, and this one can. The pipeline section of this lesson turns the exit
status into a failed build.

## In a README

Inside Markdown on GitHub or GitLab, the same text goes in a fenced block whose info string is
`mermaid`, and the site draws it. No renderer is needed, and the diagram changes in the same pull
request as the code. The cost is that you cannot check it in your pipeline unless you also run `mmdc`
on it, which is what the pipeline section does.
