---
title: Three libraries, side by side
version: 1
---

Lessons 8, 9 and 10 ran the same agent, the same tools and the same refund in three libraries. They agree on the vocabulary (an agent is a model, instructions and tools; a run is a loop; a person can be put in front of a call) and they differ on almost every default:

| | OpenAI Agents SDK (lesson 8) | Claude Agent SDK (lesson 9) | Google ADK (lesson 10) |
|---|---|---|---|
| where the loop runs | your process | the Claude Code CLI, a subprocess | your process |
| a tool is | a decorated function | an `@tool` in an in-process MCP server | a plain function |
| a tool result sent as | text, via `str()` | the text the tool wrote | a JSON object |
| a tool raises | a generic "try again" sentence | not tried in lesson 9 | the run ends, unless a callback answers |
| built-in tools offered | none | Claude Code's twenty, unless `tools=[]` | none |
| a person approves | `needs_approval`, state saved and resumed | `can_use_tool`, while the run waits | `require_confirmation`, between two runs |
| a rule before any person | a guardrail, around the agent | a `PreToolUse` hook | a `before_tool_callback` |
| traces by default | sent to OpenAI's servers | not covered here | not covered here |

**None of these defaults is wrong**, and each one was a surprise to somebody. The choice between the libraries is mostly about the provider you already use, since each is shaped around its own vendor's API and tools, and about how much of the loop you want to own. What the three lessons have in common is the method: run the library against something you can watch, read what it sent, and decide each default on purpose rather than inherit it.

That method is also the reason for lesson 7. Every row of the table is a decision `minagent` made in a line you can read, and knowing where each decision lives is what makes a library's version of it legible.

The next six lessons turn to something all three libraries already met: lesson 9's tools were an MCP server, the ADK takes MCP tools through `McpToolset`, and the OpenAI SDK through its `MCPServer` classes. **MCP** is the protocol that lets one agent use tools somebody else wrote, and it is where the questions of who may call what, with which data, stop being inside one program.
