---
title: Why write a diagram as text
version: 1
---

**A diagram written as text is a source file that a program turns into a picture.** The source can
be kept in the repository, reviewed in a pull request, compared between versions and checked by a
build, which are exactly the things lesson 11 said keep documentation alive and a drawing tool's file
cannot do well.

## What text buys

- **A readable diff.** When somebody adds the boarding sync service to a container diagram drawn in a
  diagram tool, the pull request shows a binary file changed. Written as text, it shows one new line
  for the container and one for each relationship, which a reviewer can read and question.
- **One place for the diagram and the code.** The source sits in `docs/` next to the code it
  describes, changes in the same pull request, and is checked out with the version it describes.
- **Checks.** A build can render every diagram and fail when one does not parse, as the
  pipeline section of this lesson does. A drawing tool's file breaks silently.
- **Generation.** Text can be produced by a program: a list of containers read from the deployment
  configuration, the reference documentation of lesson 11 kept true by generating it.

## What it costs

- **Less control over layout.** The tool places the boxes. Most of the time the result is good
  enough; sometimes it is not, and nudging an automatic layout is slower than dragging a box.
- **A notation to learn per tool.** Each tool has its own syntax, and lesson 1's question, *can the
  reader read it?*, now has a sibling: *can the author write it?*
- **A tool to install and keep at a version.** A diagram that rendered with one version may render
  differently, or fail, with the next. That is why this lesson pins every version.

## Three tools, three ideas

| tool | its idea | what it is best at |
| --- | --- | --- |
| **Mermaid** | a light syntax for common diagrams, drawn in the browser | flows, sequences and states in a README; GitHub and GitLab draw it inline |
| **PlantUML** | a complete text syntax for UML and more | every UML diagram of lesson 2, with precise notation |
| **Structurizr** | a **model** written once, with **views** derived from it | C4 diagrams that cannot disagree with each other |

The third is a different kind of thing from the first two. Mermaid and PlantUML describe **one
diagram per file**: if the ticketing API appears on three diagrams, it is written three times, and
the three can drift apart. Structurizr describes **the system once** and asks for views of it,
which is lesson 1's viewpoint and view, and lesson 3's *one model, many diagrams*, made into a tool.
