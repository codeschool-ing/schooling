---
title: Short-term containment: the options
version: 1
---

**Short-term containment** is the quick move that stops the damage growing while the investigation goes on.
It is not a fix: the hole the intruder came through is still there, and whatever they left behind is still
there. Lesson 14 deals with both. Here the question is only what to stop first, and what that costs.

The playbook from lesson 11 lists the moves for a compromised account. Laid side by side, each one has a
price in four currencies:

| action | stops | breaks | tells the other side | undone by |
|---|---|---|---|---|
| **block the source address** at the firewall | new connections from that one address | almost nothing | yes, at their next attempt | deleting the rule |
| **restrict a host's way out** to what it needs | data leaving to anywhere else | whatever else the host used to reach | yes, once a transfer fails | deleting the rule |
| **isolate the host** from the network | everything to and from it | the service it gives; remote access for the responders too | yes, at once | plugging it back in |
| **lock the account**, reset its password, revoke its keys | the stolen credentials, on every host | the owner's work, until new ones are issued | yes, at their next login | issuing new credentials, never the old ones |
| **switch the host off** | everything on it | the service, and the memory, which was evidence | yes | nothing brings the memory back |

Two columns decide most cases. **What it breaks** is why the business has a say: isolating the file server
stops the whole office's work, and that is not the analyst's call to make alone. **Undone by** is why the
gentler moves come first when they are enough. A firewall rule can be deleted in a second; a switched-off
server's memory cannot be read again.

The column people forget is **tells the other side**. Every action here is visible to whoever is on the
other end, and an intruder who notices they have been found may hurry, or use a second way in that the
team has not found yet. That is not a reason to wait. It is a reason to know the scope first, which is why
lesson 12 came before this one, and to make the moves that close the known ways in at the same time rather
than one by one over a morning.

For Thursday, the data has already left: 612 MB on the night. What is left to protect is everything that
has not left yet, and the account that can still log in.
