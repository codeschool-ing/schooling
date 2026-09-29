---
title: Being called back
version: 1
---

Lesson 4 turned polling round for telemetry: the device sends values to a collector that
subscribed. **A webhook turns it round for events**, and it is simpler still. A system that
knows something happened makes an HTTP request to an address somebody gave it in advance, with
a description of the event in the body. Nothing stays connected in between; each event is one
POST.

The pattern is everywhere around a network, which is why automation keeps meeting it:

| sends webhooks | when |
|---|---|
| network equipment and controllers | a link goes down, a configuration is saved, a threshold is crossed |
| NetBox, in lesson 12 | an object is created, changed or deleted |
| a Git server, in lesson 14 | somebody pushes, or a pull request is opened |
| a monitoring system | an alert fires, or clears |

And what receives them is usually one of two things: **a ticketing system**, which turns the event
into work for a person, or **a small program of your own**, which decides what to do and calls
other APIs. This lesson builds the second, and has it drive the first.

The lab's routers send webhooks from their API, the one lesson 2 used: a subscription names a URL,
a list of events and a shared secret, and from then on every change of an interface's operational
state is POSTed to that URL. The ticketing system is `tickets`, a small service desk written for the
lab; ServiceNow, Jira Service Management and the open-source desks people run have the same
shape, tickets with numbers, statuses and comments behind a token-authenticated JSON API.

**A webhook receiver is a server**, and that changes who has to be reachable: the device has to be
able to open a connection to your program. In the lab, `ctl` listens on `192.0.2.10:8080`, on the
management network the routers can reach. In production that means a firewall rule and a service
that is always running, which is the price of being told instead of asking.
