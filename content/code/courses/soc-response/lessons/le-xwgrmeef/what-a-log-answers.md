---
title: What a log answers
version: 1
---

A common picture of security monitoring is a screen that turns red when somebody breaks in. **There is
no such screen.** What exists is a set of records, written by machines that were told to keep them, and
an analyst who reads them afterwards and decides what they mean. The red screen is the last step of a
long chain, and every link of that chain is a record somebody chose to keep.

A **log** is one of those records: a line, or a structured entry, that a program writes when something
happens. A useful one answers six questions about the event it describes:

| question | in an SSH login, for example |
|---|---|
| **when** | the time stamp, with its time zone |
| **where** | the machine that wrote the line, by name or address |
| **what** | the program and the action: `sshd`, a login accepted |
| **who** | the account: `ana` |
| **from where** | the address and port the connection came from |
| **outcome** | accepted, refused, failed, disconnected |

A line missing one of them still has value, but it cannot be used alone. A firewall line knows the
addresses and the port and has no idea which person was typing. An SSH line knows the person and has no
idea how many bytes moved afterwards. **Joining two partial records on the fields they share** is most of
what the rest of this course does, and it is why the fields matter more than the format.

Logs are one of three kinds of telemetry. **Metrics** are numbers sampled over time, such as CPU load or
requests per second, and **traces** follow one request through several services. Both are covered in the
`observability` course. They help security too, since a flat line where a busy service used to be is
evidence. But the questions an incident asks, *who did what, from where, and when*, are answered by
events, and events are written as logs.

One more distinction keeps conversations short. An **event** is anything that happened: a login, a
connection, a file opened. An **alert** is an event, or a pattern of events, that a rule decided a person
should look at. An **incident** is what an alert becomes when somebody confirms that something is
actually wrong. Most events are never alerts, and most alerts are never incidents. Lesson 12 draws that
line properly.
