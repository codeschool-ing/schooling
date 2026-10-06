---
title: Privilege creep
version: 1
---

Least privilege is easy on the day an account is created. The difficulty is that **access is
granted for reasons and almost never taken away when the reasons end.** A person covers for a
colleague on holiday and keeps the access. A project needs a folder shared and the project ends. An
employee moves from support to finance and arrives in finance with support's access still attached.
After a few years, the longest-serving person in the company can reach almost everything. This is
**privilege creep**.

It is quiet by nature: nothing breaks when somebody has too much access, so nobody complains. It
shows up only in an incident, when the attacker who took a long-serving person's password finds
the keys to everything.

### Joiners, movers and leavers

The defence starts with treating access as part of three events every organisation already handles:

| event | what should happen to access | what usually goes wrong |
|---|---|---|
| **joiner** | the role's standard access, from day one, nothing more | copying a colleague's access "to be safe" |
| **mover** | the new role's access is granted **and the old role's is removed** | only the first half happens |
| **leaver** | every account disabled on the last day, including shared ones | a forgotten account in a service nobody remembers |

The leaver row is the one with the clearest risk: an account belonging to somebody who no longer
works there is an account nobody is watching. Lesson 2 listed "nobody removes an account when an
employee leaves" as a process vulnerability, and this is where it is fixed.

### Access reviews

The second defence is periodic: an **access review**, where the owner of each system or piece of
data looks at the list of who can reach it and confirms or removes each entry. The owner reviews,
not IT, for the same reason the risk owner decides in lesson 3: bruno knows whether the person
packing orders needs the finance folder; ana does not.

### Standing and temporary privilege

A permission that is always on is called **standing privilege**. For powerful access, the safer
pattern is **just-in-time** access: granted when a task needs it, for a few hours, and removed
automatically afterwards. An administrator who needs `root` on `www` twice a month should not hold
it the other twenty-eight days, because a stolen password works on all thirty.

The everyday version of this is simple and widely ignored: **an administrator uses an ordinary
account for ordinary work.** ana reads email and browses as an everyday user, and steps up to
administrative rights only for administration. Malware that arrives in an email then runs with an
everyday account's permissions, not with the keys to the shop.
