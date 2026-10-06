---
title: What the frameworks add
version: 1
---

`minagent` has the loop, the tools, the limits, the guards, the trace and the tests. The agent SDKs of the next three lessons have all of that, under other names, and a list of things `minagent` does not. Knowing which is which is the point of having written it.

| `minagent` | what an SDK typically adds |
|---|---|
| `@tool` from type hints | the same, plus Pydantic models for nested arguments and generated descriptions |
| one adapter, Anthropic's wire | adapters for many providers, often through a common interface |
| `Agent.run`, synchronous | async runs, streaming of tokens and events as they happen |
| a JSONL trace | tracing to a hosted dashboard, spans per model call and tool call, OpenTelemetry export |
| the conversation lives for one run | **sessions**: conversation history stored between runs, in memory, a file or a database |
| no handoffs | handoffs and agents-as-tools as first-class objects (lesson 6) |
| a `confirm` callback for writes | permission modes, hooks before and after each tool, approval flows |
| none | **guardrails**: checks on the input and output that run beside the agent and can stop it |
| none | MCP clients built in, so tools can come from MCP servers (lessons 11 to 16) |
| none | hosted runtimes: deploy the agent as a managed service |

## What they hide

The same list read the other way: each addition is a place where the loop does something you did not write. An SDK that retries a failed tool call, compacts the conversation when it grows, or summarises earlier turns is making decisions about cost and correctness on your behalf. **None of that is wrong; all of it is worth knowing.** The questions to ask of any SDK, which lessons 8 to 10 ask of three:

- Where is the loop, and can I set its step limit?
- How does a tool's failure reach the model: as a result, or as an exception?
- What is in a trace, and where does it go? (Some SDKs send traces to the vendor by default.)
- What does a run return when it stops?
- How do I put a person in front of a write?

A team that can answer those for its SDK is using it. A team that cannot is being used by it, and will find out on the day a run does something nobody can explain.
