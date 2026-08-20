---
title: The two roles
---

Almost everything that happens on the internet is a conversation between two parties with fixed roles. The **client** asks; the **server** answers. Your browser is a client. The computer holding the site is a server.

The roles belong to the moment, not to the machine. A web server that needs to query a database becomes the database's client at that instant. The same computer can be a client in one conversation and a server in another, at the same time.

The practical consequence is that **the client always starts**. A server does not push a page to your browser on its own: it waits to be asked. When a page seems to receive data by itself — a notification, a chat — there is a connection the client opened earlier and left open.
