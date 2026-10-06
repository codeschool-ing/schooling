---
title: When to reach for it
version: 1
---

A server is a program, a protocol and a boundary, and each has a cost. The run in section 03 started a separate process for each host, `tee` in front of it, and exchanged four to six messages before and around one tool call. For one agent that owns its tools, an in-process function (lesson 8's `@function_tool`, lesson 10's plain function) does the same job with none of that.

MCP earns its place when one of these is true:

- **The tool is used by more than one host.** The same order lookup for the support agent, the staff's chat assistant and a developer's editor: one server, written and fixed once.
- **The tool belongs to someone else.** Another team, or a vendor, publishes a server; you connect to it rather than writing an adapter for their API, and they can change their side without breaking yours as long as the protocol holds.
- **The tool should run somewhere else.** A server with access to the orders database can run next to the database, under its own account, and the agent's host reaches it over the network with credentials (lesson 16) instead of holding the database password itself.
- **The person, not the developer, chooses the tools.** Assistants that let their users add servers are what made MCP common: the host is fixed, and the tools are whatever the person installs.

The third reason is also a security argument. A tool in your process runs with your process's permissions, and so does a local stdio server (`ai-dev` lesson 7 section 08 says so plainly). A remote server can be given exactly the access it needs and no more, which is lesson 17's least privilege drawn as a process boundary.

And the cost in the other direction: **every server you connect is code you run or a service you trust**, with its own descriptions in front of your model. The question to ask is not whether a server exists for something, but whether you would accept its author's words in your prompt and its process on your machine or in front of your data.
