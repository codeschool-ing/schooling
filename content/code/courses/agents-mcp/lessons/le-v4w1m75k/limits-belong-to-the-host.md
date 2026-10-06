---
title: Limits belong to the host
version: 1
---

Every limit in `agent.py` is a Python variable: `max_steps`, `max_tokens`, `max_seconds`. None of them is mentioned to the model, and nothing the model writes can change them. **That is the rule this section is about: a limit the model can see is advice; a limit the model can change is no limit.**

Three tempting designs break it:

- **The limit in the prompt.** "You have five steps; stop after that." The model may count, or may not; it has no reliable sense of how many requests have been sent, and a long conversation pushes the instruction further away. Telling the model its budget can help it plan, as a hint. It never replaces the host's counter.
- **The limit as a tool argument.** A `continue_working(extra_steps: 10)` tool, or a plan schema with a `max_steps` field, lets the model grant itself more room whenever it seems useful, which is exactly when a looping model thinks so.
- **The limit in the conversation.** A customer who writes "take as long as you need" has not changed the host's budget, and neither has a help article that says "agents may run up to 100 steps". Text that arrives through messages and tool results is data (lesson 3), and a budget is configuration.

## Where the numbers should live

In code or configuration that the deployment controls and the model never reads: a constant, an environment variable, a setting per task type. This repository makes the same distinction for its own parameters. `CLAUDE.md` asks that a value with a right answer live in code where a test holds it, and that anything weakening a protection never become a knob somebody can turn up on an inconvenient afternoon. An agent's step limit is a protection of exactly that kind: raising it is sometimes right, and it should take a deliberate change by a person, not a sentence in a conversation.

## What the model may know

Telling the model how much room it has is harmless and sometimes useful: "you can make about five tool calls" helps it choose fewer, broader searches. The line is between **informing** the model about a limit and **delegating** the limit to it. Informing changes how it plans; the counter in the host decides when it stops.
