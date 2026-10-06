---
title: From a paper to every agent
version: 1
---

`prompt-engineering` lesson 29 introduced ReAct as a prompt format: the model writes a `Thought:` line, then an `Action:` line naming a tool, the program appends an `Observation:` line with the tool's result, and the cycle repeats until an `Answer:`. This lesson assumes that format and runs it as code. **The format is the easy part; what breaks is the plumbing around it**, and that is what the next seven sections take apart.

## What the paper actually did

*ReAct: Synergizing Reasoning and Acting in Language Models* (Yao and colleagues, 2022; published at ICLR 2023) tested the idea on two kinds of task. On question answering and fact checking (HotpotQA and FEVER), the model's only tools were three actions over Wikipedia: `search[entity]`, `lookup[string]` and `finish[answer]`. On interactive tasks (ALFWorld, a text game of household chores, and WebShop, a simulated online shop), the actions were moves in the environment.

Its finding was about the combination. Reasoning alone, chain of thought with no tools, made up facts it could have looked up. Acting alone, tool calls with no written reasoning, lost track of what it was trying to do over long tasks. **Interleaving the two let each thought say what was missing and each observation correct the next thought**, and it left a trace a person could read to see where a run went wrong.

## What changed since

The paper's model knew nothing about tools; everything happened in plain text, and a regular expression found the actions. Providers then built tool calling into their APIs: the request carries tool definitions as JSON Schema, and the reply carries a structured tool call instead of an `Action:` line (lesson 4 is about those schemas). **The loop is the same loop**; what moved is who parses the action. In text ReAct your regular expression does it, and it can misread. With native calls the provider returns the arguments already as JSON, checked against the schema the request declared.

So this lesson runs both. Sections 03 and 04 run text ReAct, because it shows every moving part in the open and one failure that native calls make rarer. Section 05 runs the same task with native tool calls, which is how every agent from lesson 7 on is built.
