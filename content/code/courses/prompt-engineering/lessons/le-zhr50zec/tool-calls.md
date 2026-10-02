---
title: A request written as text, and a program that carries it out
version: 1
---

Assistants that look up the weather, run code or book a table seem to do those things themselves.
**A model cannot run anything. It writes text, and part of that text can be a request, in a format
agreed in advance, for a program to run a tool.** The program around the model reads the request,
runs the tool, and puts the result back into the text; then the model is asked to continue, with
the result in front of it.

Without that arrangement, two things you have met before go wrong. Asked for today's date, a model
can only write a likely date, which is lesson 5's problem; asked for 3 × 42.50, it does arithmetic
on chunks of digits, which is lesson 3's. A tool replaces the likely answer with a looked-up or
computed one.

## Telling the model what it can ask for

The model learns which tools exist from its input. In the simplest form the description is part
of the prompt, with the format the program will look for. This one was written by the course as an
illustration, for the tools of the workbench:

```localised
You can ask for these tools. Write one request per turn, on a line of
its own, and wait for the result:
  Action: today[]            today's date
  Action: calculator[sum]    arithmetic with numbers and + - * /
When you have everything you need, write:
  Answer: your reply to the customer
```

At the time of writing (2026), the APIs of the large providers have a field for this instead of a
paragraph in the prompt. Each tool is described by a name, a sentence saying what it does, and a
JSON Schema for its input (lesson 19 is about schemas). The model's reply then carries the tool
call as a separate, structured part, and your code sends the result back in a message of its own.
The field names differ between providers; a definition for the calculator looks like this (not
run: the workbench has no key):

```json
{
  "name": "calculator",
  "description": "Arithmetic with numbers and + - * /. Returns the result as a number.",
  "input_schema": {
    "type": "object",
    "properties": {"expression": {"type": "string"}},
    "required": ["expression"]
  }
}
```

**The description is a prompt too.** The model decides whether and how to call a tool from that
one sentence, so "Arithmetic with numbers and + - * /" is doing real work: it tells the model
which operations it may send, and that `sqrt(2)` will not work.

## A run on the workbench

`agent` is the program that sits around the model. Its input is a file holding the model's turns,
one block per turn, separated by `---`; lines starting with `#` are notes and are skipped. **The
turns are written by the course, knowing what the tools will return, because no model is reachable
from the workbench.** Everything else is real: `agent` reads each turn, finds the `Action:` line,
runs the tool and prints what it returned. Here is a question about a cake order, and the turns a
model might write for it:

```
ana@lab:~/pe$ cat runs/order.txt
# Question: Bruno wants three whole cakes at R$ 42.50 each, to collect
# tomorrow. What day is tomorrow, and what is the total?
Action: today[]
---
Action: calculator[3 * 42.50]
---
Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
```

And the run:

```
ana@lab:~/pe$ agent runs/order.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
step 3
  model> Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
done: an answer after 3 steps
```

Read the lines by who wrote them. The `model>` lines are the turn file. **The `tool>` lines were
printed by real tools**: the date came from `today`, and `127.5` from the calculator, which
evaluated `3 * 42.50`. The answer then combines the two, and that last step is the model's own:
working out that the day after Friday 2 October is Saturday 3 October, and writing `127.5` as
`R$ 127.50`. A tool supplies the fact; the model still decides what to ask for and what the result
means.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three boxes from left to right. Inside a dashed boundary labelled the program around the model are the model, which writes text and runs nothing, and the loop. The model sends the loop the line Action: calculator[3 * 42.50]. The loop checks whether the tool is allowed and runs it. Outside the boundary are the tools, the only part that acts. The calculator returns 127.5 to the loop, and the loop adds the result to the text the model reads next.\"><defs><marker id=\"tool-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"444\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"28\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the program around the model</text><rect x=\"30\" y=\"90\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"92\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">writes text, runs nothing</text><rect x=\"330\" y=\"90\" width=\"112\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the loop</text><text x=\"242\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Action: calculator[3 * 42.50]</text><path d=\"M154 104 L328 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><path d=\"M328 146 L156 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"242\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the result, added to the text</text><rect x=\"586\" y=\"90\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"646\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the tools</text><text x=\"646\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the only part that acts</text><path d=\"M442 104 L584 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allowed?</text><text x=\"514\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">then run it</text><path d=\"M584 146 L444 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">127.5</text></svg>", "caption": "What a tool call is. The model only writes a line asking for a tool; the program around it decides whether to run it, runs it, and puts what came back into the text the model reads next."}
```

## What "agent" means here

The word is used loosely, for anything from a chatbot with a search box to a system that runs for
hours. In this course **an agent is a model running in a loop like this one**: it may ask for a
tool, the program runs it, and the loop goes round until the model writes an answer or a limit is
reached. The loop is the subject of the next section, and the program, not the model, holds every
limit in it.
