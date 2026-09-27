---
title: A runbook for a stopped print queue
version: 1
---

When a printer reports a fault, such as a paper jam, the print system stops its queue and **leaves it
stopped** after the fault is cleared. Users see a printer that works and prints nothing. The office's
runbook for it:

**Runbook: a print queue that stopped**

*When to use it*: "the printer is on but nothing prints", on one printer, for everyone who uses it.

*Before you start*: access to the computer that holds the queue, with `sudo`. Tell the user you are
checking the queue, and ask them not to send the document again: it is probably waiting already.

1. `lpstat -p QUEUE`. **Expected**: `disabled`, with a reason. If it says `idle` or `printing`, this is
   not the problem: stop and use the general method, lesson 1.
2. `lpstat -o QUEUE`. Note how many jobs are waiting; they will print once the queue starts.
3. **Ask** whoever is next to the printer to fix the reason, and to confirm it: the jam cleared, paper
   loaded, the cover closed. Do not continue until they say so.
4. `sudo cupsenable QUEUE`, then `lpstat -p QUEUE`. **Expected**: `idle` and `enabled`.
5. `lpstat -o QUEUE`. **Expected**: the waiting jobs gone, printed. Ask the user to confirm the paper
   came out.

*Stop and escalate if*: the queue stops again within minutes with the same reason (the printer itself
is faulty: the printer's supplier), or the reason mentions anything but paper, toner or a cover.

*Undo*: `sudo cupsdisable QUEUE` stops it again.

*Owner*: the service desk. *Last reviewed*: when it was last followed and something was different.
