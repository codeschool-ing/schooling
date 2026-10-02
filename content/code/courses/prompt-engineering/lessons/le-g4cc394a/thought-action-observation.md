---
title: Thought, Action, Observation, and then an Answer
version: 1
---

Lesson 6 gave a model tools: it writes a line naming a tool, a program runs it, and the result goes
back into the text. That lesson left open how the model decides what to call, and in what order.
The tempting picture is an agent that plans the job in its head and then carries it out. **ReAct
does the opposite: the model reasons in the open, one small step at a time, and asks the world
after each one.** The name is short for *reasoning and acting*, from a 2022 paper,
"ReAct: Synergizing Reasoning and Acting in Language Models".

The format is four kinds of line:

| line | who writes it | what it holds |
|---|---|---|
| `Thought:` | the model | what it knows so far, and what it needs next |
| `Action:` | the model | one tool, and what to give it: `search[...]`, `calculator[...]` |
| `Observation:` | **the program running the loop** | what the tool returned, word for word |
| `Answer:` | the model | the reply, once nothing more is needed |

Thought, Action and Observation repeat as many times as the task takes, and an Answer ends it. The
`Thought` is chain of thought from lesson 26, cut into pieces. **What ReAct adds is that every
piece of reasoning is followed by a fact the model did not make up.**

## Why both halves

Each half fails on its own, and in a way you have already met. Reasoning with no tools works out an
answer from whatever the model finds likely, so a rule it half-remembers turns into a confident
step (lesson 5). Tools with no reasoning give you a list of calls and no record of why each one was
made, so when the answer is wrong you cannot tell which call misled it.

Put together, the thought says what is missing, the action fetches it, and the next thought starts
from what came back. A person reading the trace afterwards can point at the exact line where things
went wrong, and that matters more than it sounds in a system nobody watches while it runs.

The prompt that sets this up describes the tools and the format, and then hands over the question.
This one was written by the course as an illustration:

```localised
Answer the question. You can use these tools:
  search[words]        the best matching line of the café's staff handbook
  calculator[sum]      arithmetic with numbers and + - * /
Use this format, and write one Action at a time:
Thought: what you know and what you need next
Action: one tool call
Observation: (the tool's reply is written here for you)
... repeat as needed, then:
Answer: the final answer

Question: four soups of the day, R$ 27.90 each, paid by card, all served cold.
How much goes back, how, and does anybody have to approve it?
```

## A full run

`agent` is the loop from lesson 6. The turns it plays back are in a file, separated by `---`, and
lines starting with `#` are notes it skips. **The turns below were written by the course, knowing
what the tools would return**, because no model is reachable from the workbench. Everything printed
after `tool>` is real: the handbook search and the arithmetic actually ran.

```
ana@lab:~/pe$ cat runs/refund.txt
# Question: four soups of the day, R$ 27.90 each, paid by card, all served
# cold. How much goes back, how, and does anybody have to approve it?
Thought: The handbook has the rules for refunds. I need the one about approval.
Action: search[refund approval manager]
---
Thought: Above R$ 100 needs the shift manager. Now the total for four soups.
Action: calculator[4 * 27.90]
---
Thought: 111.6 is above 100, so the manager approves it. How does the money go back?
Action: search[refund card cash]
---
Thought: Back to the card they paid with, not in cash.
Answer: R$ 111.60, refunded to the card, once the shift manager has approved it.
ana@lab:~/pe$ agent runs/refund.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: The handbook has the rules for refunds. I need the one about approval.
  model> Action: search[refund approval manager]
  tool>  refunds.md     A refund above R$ 100 needs the shift manager's approval.
step 2
  model> Thought: Above R$ 100 needs the shift manager. Now the total for four soups.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
step 3
  model> Thought: 111.6 is above 100, so the manager approves it. How does the money go back?
  model> Action: search[refund card cash]
  tool>  refunds.md     Refunds are made to the card or method used to pay, never in cash for a card payment.
step 4
  model> Thought: Back to the card they paid with, not in cash.
  model> Answer: R$ 111.60, refunded to the card, once the shift manager has approved it.
done: an answer after 4 steps
```

Four steps and three tool calls. Read the answer against the trace and **every part of it has a
source**: the approval rule is a line of `refunds.md`, the amount is the calculator's `111.6`, and
"to the card" is the second handbook line. The only thing the model contributed was the order of
the questions and the comparison of 111.6 with 100, and both are written down where you can check
them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A sequence diagram with three columns: the model, the loop and the tools. In step 1 the model writes Action: search refund approval manager. The loop checks the tool is allowed and runs it. The tool returns the handbook line, a refund above R$ 100 needs the manager&#x27;s approval. The loop adds it to the text as an Observation and hands it back to the model. Steps 2 and 3 do the same with the calculator and search. In step 4 the model writes an Answer with no Action, and the loop stops. The loop also counts the steps.\"><defs><marker id=\"react-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"18\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><path d=\"M110 48 L110 199\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M110 227 L110 315\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"290\" y=\"18\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the loop</text><path d=\"M360 48 L360 199\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M360 227 L360 271\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"540\" y=\"18\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the tools</text><path d=\"M610 48 L610 199\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M610 227 L610 315\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">step 1</text><text x=\"235\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Action: search[refund approval manager]</text><path d=\"M110 98 L358 98\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><text x=\"485\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">allowed? then run it</text><path d=\"M360 122 L608 122\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><text x=\"485\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">A refund above R$ 100 needs…</text><path d=\"M610 158 L362 158\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><text x=\"235\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Observation: added to the text</text><path d=\"M360 182 L112 182\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><rect x=\"40\" y=\"200\" width=\"640\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">steps 2 and 3: the same, with calculator and search</text><text x=\"235\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Answer: R$ 111.60, refunded to…</text><path d=\"M110 260 L358 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><rect x=\"265\" y=\"272\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">done: no Action, an Answer</text><text x=\"468\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and counts the steps</text></svg>", "caption": "The run as a sequence. The model only writes text; the loop reads the Action line, runs the tool, and hands back what it returned. The loop, not the model, decides when to stop."}
```

## The Observation is never the model's

In the table above, one line is written by somebody else. That is deliberate, and real systems
enforce it. A model asked to continue a ReAct trace can carry on past its own Action and
write an `Observation:` too, with whatever result seems likely, and then reason from that invented
result. So the program sets `Observation:` as a stop sequence (lesson 16): **generation halts the
moment the model starts to write what the tool said**, the loop runs the tool, and writes the
Observation itself.

`agent` gets the same effect another way, by reading one Action per turn and printing what the tool
returned under `tool>`, never anything the turn claims. Either way the rule is the one that makes
the method worth using: the facts in the trace come from outside the model.
