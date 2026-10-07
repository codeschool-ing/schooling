---
title: The office this course works in
version: 1
---

Every ticket in this course happens in one small office, and every terminal session you will read was
recorded there, on real computers. **You read them; you do not need to type any of it.** The output is
the point: what a command answered, and what that answer rules out.

The office has four computers, all running Ubuntu 24.04:

| name | what it is |
|---|---|
| `host` | the technician's own computer. She is called ana, and every session is hers |
| `pc1`, `pc2` | the desks: the computers Carla, Bruno, Daniel and Elisa work at |
| `srv1` | the server: the intranet page everybody opens by the name `intranet`, and in lesson 7 a system another team runs |

A prompt says where a command ran. `ana@pc1:~$` is ana typing on `pc1`, reached from her own computer
with ssh, as a technician with remote access would. `elisa@pc1:~$` is Elisa's own session.

The four are virtual machines on a network of their own, `10.30.0.0/24`, with no route to anything
else. That is what made it safe to break them: **each fault was set up on purpose before the recording**,
a wrong line in a file, a full disk, a printer stopped with a jam. Where the office lacks something a
real one has, the lesson says what stands in for it. None of the computers has a desktop, for instance,
so a screen shared for remote support is a terminal one.

You are not asked to build it, because **the practice in this course is judgement**: which question to ask,
which check rules out the most, what goes in the ticket, when to stop and hand it on. The questions
after each lesson check that, and none of them needs a terminal.

If you want to run something anyway, use the Linux you installed in the Operating Systems course,
lesson 3, "Installing and setting up a Linux distribution". The commands that only read, such as
`getent hosts`, `lpstat` and `df -h`, work there and answer about your computer, so their numbers will
differ from the office's. The two programs this course shows whole, the business-hours calculator in
lesson 6 and the inventory script in lesson 11, run there as they are. Anything that names `pc1`, `pc2`,
`srv1` or `intranet` will not: **those names exist only in the office**. And a command that changes
something, anything run with `sudo`, belongs on a computer you can afford to break.
