---
title: The host decides
version: 2
---

The specification gives the host a list of jobs: creating and managing clients, controlling their permissions and lifecycle, enforcing security policies and consent, handling the person's authorisation decisions, coordinating the model, and aggregating context across clients. Every finding in this lesson sits on that list:

| what was seen | whose decision |
|---|---|
| the server ran as ana, with her files | the host starts the server; the person installs it |
| it received 4 environment variables, or 31 with two API keys | the host's client, and the configuration it accepts |
| it saw only the call's arguments | the host, which decides what goes in a request |
| the clients declared different capabilities | each host, for what it can do on a server's behalf |
| two tools with one name: refused, renamed, or silently shadowed | the host |

Not one of these is decided by the protocol, and not one by the server. A server can be well written and still be handed your keys; it can be honest and still be shadowed by another. That is why the questions to ask before connecting a server are questions about the host:

- **What will the server process inherit?** User, files, environment, network.
- **What will it be sent?** Only arguments, or more, and from which conversations.
- **What else is connected at the same time?** Names, and what one server's output might lead the model to do with another's tools.
- **Which calls need a person?** The host's approval step, lessons 8 to 10, applies to MCP tools exactly as to local ones.

Lesson 15 builds a host, and makes each of these decisions in code where they can be read. Lesson 17 tests them against the course's lab.
