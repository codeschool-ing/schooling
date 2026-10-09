---
title: An agent is a loop
version: 2
---

"Agent" is used for many things, and the useful definition is the mechanical one. **An agent is a
model in a loop with tools**: the model reads the task, decides to call a tool, your code calls it and
sends back the result, and the model decides again, until it answers or something stops it. Nothing
about it is new except the loop. Lesson 1's model still produces one reply per request; the agent is
the code that keeps asking.

::: track ai
`agents-mcp` built agents with planning, memory and several tools working together. This lesson is
the smallest version that is still honest: one loop, three tools, one MCP server, and the four
guards that every agent in production needs whatever else it has.
:::

::: track *
You have used one already if you have used an assistant's agent mode (lesson 3 section 08). This
lesson builds the loop that sits behind it, so the limits on it stop being a mystery.
:::

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The agent loop. The host sends the conversation and the tool definitions to the model. The model replies with an answer, which ends the loop, or with a tool call. The host checks the call against its guards, calls the tool on the MCP server, and appends the result to the conversation, then asks again.\"><defs><marker id=\"ag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decides</text><rect x=\"285\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the host</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acts and guards</text><rect x=\"550\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the tools</text><text x=\"625.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do the work</text><path d=\"M283 84 L172 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"228\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conversation + tools</text><path d=\"M172 116 L283 116\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"228\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answer, or a tool call</text><path d=\"M437 84 L548 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"492\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">call, if allowed</text><path d=\"M548 116 L437 116\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"492\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">result</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">guards: steps, repeats, approval</text><path d=\"M95 132 L95 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"105\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">an answer ends the loop</text></svg>", "caption": "The model never runs anything. Every effect happens in the host, which is where every limit lives."}
```

## Who does what

- **The model decides.** It reads the conversation and the tool descriptions, and its reply is either
  an answer or a request to call a tool with some arguments. It runs nothing.
- **The host acts.** Your code receives the request, decides whether to allow it, calls the tool,
  and appends the result to the conversation. Every effect on the world happens here, in code you
  wrote and can read.
- **The tools do the work.** An order lookup, a page of the handbook, a refund. They are ordinary
  functions, and lesson 7 section 05 shows how MCP lets one program offer them to any host.

The split is the safety argument for the whole design. **A model cannot do anything a host does not
do for it**, so every limit an agent needs (which tools, which arguments, how many steps, which calls
need a person) is a line of code in the host, not a sentence in the prompt.

## What the loop costs

Each step is a full request, carrying the whole conversation so far: the question, every tool call,
every result. Lesson 2 section 06's arithmetic applies, and tool results are often long. Lesson 7
section 09 measures three-step loops in which each request is bigger than the last.
