---
title: Local and remote
version: 1
---

Every server in lessons 11 to 15 was **local**: a program the host started on ana's machine, talking over stdio, running as ana. Lesson 12 measured what that means. A **remote** server is a service on another machine, reached over Streamable HTTP. The protocol's messages are the same; almost everything around them changes.

| | local (stdio) | remote (Streamable HTTP) |
|---|---|---|
| who starts it | the host, as a child process | somebody else, as a service |
| who it runs as | the person running the host | its own account |
| what it can read | everything that person can | what its own machine holds |
| what it inherits | an environment the host chose (lesson 12) | nothing from the host |
| how it is reached | a pipe | a network, so TLS |
| who is asking | whoever started it | must be proved, on every request |
| how long it lives | as long as the host | independently |

The last three rows are where a remote server needs work a local one does not: **TLS**, so the client knows it is talking to the real server, and **authorisation**, so the server knows who is asking and what they may do. The specification puts authorisation in a section of its own, built on OAuth 2.1, and requires it to be done in specific ways; this lesson builds the server's half of it and reads the client's half.

The gain is the one lesson 11 named: a remote server can be given exactly the access it needs and no more, and it can run next to the data instead of on every person's laptop.
