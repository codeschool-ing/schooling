---
title: What it is for, and what it costs
version: 1
---

What a support technician uses virtual machines for, in the order you are likely to meet them:

- **A place to try things.** An update, a new version of a program, a setting you are not sure of: on
  a guest first, on the customer's computer after.
- **Another operating system.** A Windows guest on a Linux laptop, or the reverse, to follow a
  customer's steps on the system they actually have.
- **A lab.** A client, a server and something to attack or repair, on one computer, on a network of
  their own. Lessons 14 and 15 build one, and the courses after this one use it.
- **Old software.** A program that only runs on an old system keeps running inside a guest of that
  system after the last real computer that ran it has gone.
- **Going back.** A snapshot, lesson 9, saves a guest's state and returns to it in seconds, which is
  what makes breaking things on purpose affordable.

None of it is free. **Everything a guest has, the host gives up.** The 1 GiB guest here cost the host
about 1.5 GiB while it ran. Its two processors are time taken from the host's 4, and five
busy guests on four processors take turns. Its disk grows as it writes, and ten overlays on one base
can fill a host's disk slowly, where nobody is watching. And a guest is slower than the host at
anything that goes through the hypervisor: a little slower with the processor's help, a lot slower
without it, as on the computer this course was recorded on. Lessons 2 and 8 measure how much.

The rule of thumb that follows: **give a guest what its job needs, not what the host can spare**, and
switch off the ones you are not using.
