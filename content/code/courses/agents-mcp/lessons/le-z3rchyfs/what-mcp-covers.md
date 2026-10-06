---
title: What the protocol covers
version: 1
---

MCP standardises the conversation between a client and a server, and not much else. A server can offer three kinds of thing, which the specification calls **primitives**:

| primitive | what it is | who decides to use it |
|---|---|---|
| **tools** | functions the model can ask to call, with an input schema | the model asks; the host allows or refuses |
| **resources** | data addressed by a URI, such as a file or a record, for the host to read and give the model as context | the host or the person |
| **prompts** | templates a person can pick, such as a slash command, with arguments | the person |

The server in this lesson offers one tool. Lesson 14 builds a server with all three.

A server can also need something from the client in the middle of a request: a confirmation from the person, a choice, a credential. In the 2026-07-28 revision that is done by **multi round-trip requests**: instead of a result, the server returns one of type `input_required` listing what it needs, and the client retries the request with the answers. Lesson 13 shows one. Earlier revisions did it with requests from the server to the client, which needed a connection that stayed open; making the protocol stateless is what changed that.

Some features are on their way out, and the specification keeps a registry of them. Under the 2026-07-28 revision these are **deprecated**: **roots** (the client telling the server which directories it may use), **sampling** (the server asking the client's model to generate text), **logging** as a protocol feature, dynamic client registration, and the old **HTTP+SSE transport**. Deprecated means new implementations should not adopt them and existing ones should migrate; none has been removed yet. Courses and articles written in 2025 describe roots and sampling as core features, which they were then.

The transports are two: **stdio**, for a server the host starts as a local program, and **Streamable HTTP**, for a server somewhere else. Lessons 13 and 16 use both.
