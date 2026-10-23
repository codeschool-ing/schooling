---
title: Choosing a tool, and when not to use one
version: 1
---

**The three tools overlap less than they seem to.** Mermaid is for diagrams that live where people
read Markdown; PlantUML is for precise UML; Structurizr is for C4 models where several views must
agree. Most teams end up with two of them.

| you need | use | because |
| --- | --- | --- |
| a flow or a state machine in a README | Mermaid | GitHub and GitLab draw it with no tool, next to the code |
| a sequence diagram with fragments, in exact UML | PlantUML | it follows lesson 2's notation closely |
| a class, component or deployment diagram in UML | PlantUML | Mermaid covers some of these, less precisely |
| context, container and component diagrams that must agree | Structurizr | one model, several views |
| a diagram for a board presentation | a drawing tool | layout and emphasis matter more than diffs, and it is not maintained |

## What Carcará settled on

- **Structurizr** for the C4 model of ticketing and boarding, in the architecture repository, with
  the views exported to Mermaid and rendered in the pipeline;
- **Mermaid** inside the services' READMEs, for the one or two flows each team wants next to its
  code;
- **PlantUML** for the sequence diagrams in design documents and decision records, where the
  arrowheads matter;
- **a drawing tool** for the quarterly presentation to the board, drawn fresh each time from the
  model and not kept, which lesson 14 discusses.

Written down, that is a decision record: ADR-0021, *Diagrams as text, by kind*.

## When text is the wrong tool

Text loses where layout is the message. A diagram meant to persuade, with a deliberate position for
each box and a highlighted path, is better drawn by hand, and **better not kept**: it is a slide,
made for one meeting, and lesson 11's rules about dead pages apply to it the day after. The test from
lesson 1 still decides: **who reads it, and what question does it answer?** If the reader is a
reviewer of a pull request, use text. If it is a board deciding a budget, use whatever makes the one
point clearest.
