---
title: A hole in the wall, on purpose
version: 1
---

A guest is useful because it is walled off from the host: lesson 1 deleted a guest's whole system and
the host did not notice. **A writable shared folder is a door in that wall.** Whatever runs in the guest
can create, change and delete files in it, and they are the host's files:

- A guest infected by ransomware encrypts every file it can write, **the shared folder included**.
- A test that goes wrong and deletes a folder's contents deletes the host's copy, because there is only
  one copy.
- A guest you do not trust, such as lesson 14's target, can leave something in the folder for the host
  to open later.

So share what the guest needs and nothing more, **read-only whenever the guest only has to read**, as
`docs` was, and never share a whole home folder or a disk. A guest that is going to run anything
you do not trust gets no shared folder at all, lesson 15, and files reach it the long way, over the network, one at
a time.
