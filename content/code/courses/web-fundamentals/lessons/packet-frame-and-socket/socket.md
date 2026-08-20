---
title: Socket: a program's address
---

The IP finds the machine, but a machine runs dozens of networked programs at once. What separates them is the **port**, a number identifying which program should receive that data.

The pair `IP:port` is the **socket** — `192.168.0.10:443`, for example. A connection is identified by four things: source IP and port, destination IP and port. Because the source port changes with every new connection, you can open ten tabs of the same site without the responses getting mixed up.

Common ports are worth memorising: `80` for HTTP, `443` for HTTPS, `22` for SSH, `5432` for PostgreSQL. When a service "is not responding" and the machine is up, the right question is almost always whether anything is listening on that port.
