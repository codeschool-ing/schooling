---
title: What a real EDR adds
version: 1
---

**Every weakness of this lesson's EDR is a place where a product made a different choice.** That
makes the small one a good way to read a product's datasheet: each feature on it answers one of
the gaps you have now seen for yourself. None of the products below was run for this course; what
they do is described from their vendors' documentation.

## Told, not looking

The sensor polled `/proc` and missed twenty processes out of twenty. A product's sensor is
**called by the kernel** at the moment something happens, so nothing is too short to see and the
parents are still alive when the record is made.

- On Linux the modern way is **eBPF**: small programs the kernel runs at chosen points, such as the
  moment a program is executed or a connection is opened, verified by the kernel before they are
  allowed to load. Falco, Tetragon and most commercial Linux sensors work this way. The older way
  is the audit trail that `auditctl` could not reach from inside a container.
- On Windows the same role is played by **kernel callbacks**, which a driver registers to be told
  about every new process, thread and image loaded, and by **Event Tracing for Windows** (ETW), the
  stream of events the system and its components write. Sysmon, Microsoft's free tool, records
  much of this to the event log and is the usual first step before a full product.

## Hard to switch off

`sensor.py` is a process like any other: root can stop it with one command, and so can anybody who
becomes root. Products defend themselves, which is called **tamper protection**. The agent runs
under the system's own protection, refuses to be stopped or uninstalled without a code from the
console, and its silence is itself an alert: a machine that stops reporting is treated as a
machine that needs a look.

## Somewhere else

The telemetry here sits on `web` itself, in `/var/log/sensor.jsonl`, where anybody who controls
the machine can edit it. A product sends every record off the machine as it is made, to a console
that keeps it for weeks or months and puts every machine's records side by side. That is what
answers the questions a single machine cannot: has this hash, this parent chain or this address
appeared anywhere else in the company.

## Response as a button

Isolation here was a file you wrote and loaded by hand. A product does the same thing from the
console, at any hour, and can do it **automatically** when a rule is certain enough. It can also
collect the files and memory a responder needs, and kill a process on every machine at once.

## The names you will meet

| product | what it is |
|---|---|
| Microsoft Defender for Endpoint | Microsoft's commercial EDR, built into Windows and available for Linux and macOS |
| CrowdStrike Falcon, SentinelOne | commercial EDRs with their own sensor and console, on every major system |
| Wazuh | open source: an agent, rules and a console, with file integrity and log analysis as well |
| osquery | open source: the machine's state as SQL tables, asked by a person or on a schedule |
| Elastic Defend | the endpoint agent of the Elastic stack, sending to Elasticsearch |

## What none of them removes

**Rules still have to be written by somebody who knows what the machine does.** A product ships
thousands, and every one of them fires on something legitimate somewhere: an administrator's
script looks like an intrusion to a rule that has never met that administrator. The first months
of any EDR are spent **tuning**: deciding, alert by alert, which ones describe this company's
normal and can be silenced for these machines, and which ones were right. A product that nobody
tunes produces so many alerts that nobody reads them, which is the same as having none.
