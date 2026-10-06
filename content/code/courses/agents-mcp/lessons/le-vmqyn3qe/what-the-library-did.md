---
title: What the client library did
version: 1
---

`mcp_host.py` decided its policy; the `mcp` SDK's `Client` handled the protocol. It is worth knowing which is which, because each is somewhere a bug can hide.

**What the `Client` did without being asked:**

- **Chose the revision.** Its default mode, `auto`, probes `server/discover` first and falls back to the `initialize` handshake on a legacy server, which is what lesson 11's OpenAI host showed on the wire.
- **Ran the multi round-trip loop.** When `refunds` answered `input_required`, `call_tool` called `server_asks`, retried with the answer and the sealed `requestState`, and returned the final result. It stops after a fixed number of rounds (`input_required_max_rounds`), so a server that kept asking could not hold the call forever.
- **Cached lists.** It honours the servers' `ttlMs` and `cacheScope` hints; with `ttlMs: 0`, as these servers send, nothing is reused.

**What it declared, because of what the host gave it:** `elicitation`, since `server_asks` exists. It did not declare **sampling**, because the host gave it no `sampling_callback`: a server connected to this host cannot ask the host's model to write text. That is a choice with a reason. Sampling lets a server spend the host's model on its own prompts, and it is deprecated in the 2026-07-28 revision; a host that does not need it should not offer it.

**What the host still had to write:** everything in lesson 12's table. Which variables a server inherits, how tools are named, what the model is told about a tool's origin, which calls need a person, which resources the model may cause to be read, and what is written down. None of it is in the protocol, and none of it was in the library.
