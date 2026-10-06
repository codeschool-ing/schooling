---
title: Why split the work at all
version: 1
---

The common picture is a team: a manager agent and a row of expert agents, each better at its job than one generalist could be, so a multi-agent system must be the more capable design. **Nothing in the model makes a specialist more expert.** The orders specialist in this lesson calls the same `scripted-1` as everybody else. What a split changes is what each agent sees and what each may do, and those are real reasons, with real costs.

The reasons that hold up:

- **A smaller context per agent.** A specialist starts its own conversation with one question, not the customer's whole history and every other agent's tool results. A shorter conversation is cheaper per request and leaves the model less to get lost in, which matters most for long tasks where one agent's context would fill with results unrelated to the current step.
- **Fewer tools per agent.** Each specialist here has one or two tools instead of three. A model choosing between two tools makes fewer wrong choices than one choosing between twenty, and the descriptions can be written for one job.
- **Least privilege per agent.** The catalogue specialist cannot look up orders at all. If something persuades it to try, there is no tool to call. Lesson 17 builds on this: an agent that reads untrusted content should be one that cannot act.
- **Parallel work.** Independent questions go to independent agents at the same time. For a research task that reads ten sources, ten workers can each read one.

The costs, which section 05 measures:

- **More requests and more tokens.** Every agent has its own system prompt and its own conversation, and the orchestrator pays again to read each specialist's answer.
- **A boundary where information is lost.** Each agent knows only what crossed into it, and section 08 shows a fact getting lost at that line.
- **Harder debugging.** A wrong answer may come from the orchestrator's question, a specialist's tool call, a specialist's summary, or the orchestrator's reading of it. The trace has to show all four.

So the question is never "single or multi-agent?" in the abstract. It is whether the context, tool or privilege separation is worth more than the requests, tokens and boundary it adds, for this task.
