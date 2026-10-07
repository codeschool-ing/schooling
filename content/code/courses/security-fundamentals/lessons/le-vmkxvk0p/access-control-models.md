---
title: Access control models
version: 1
---

Authorisation needs rules, and there are four classic ways to organise them. They are not rival
products; most real systems mix two or three. Knowing their names lets you read a design and see
where its decisions come from.

| model | who decides | how a rule reads | at the shop |
|---|---|---|---|
| **DAC**, discretionary | the owner of each resource | "bruno shares this folder with ana" | Linux file permissions, a shared spreadsheet |
| **MAC**, mandatory | a central policy nobody can override | "only people cleared for *confidential* read *confidential* files" | rare in business; common in military and government systems |
| **RBAC**, role-based | the organisation, through roles | "members of `hr` may read any payslip" | the portal's `hr` rule, the `sudo` rule of lesson 6 |
| **ABAC**, attribute-based | a policy over attributes of the user, the resource and the context | "staff may read the handbook from a managed device during working hours" | the Zero Trust decisions of lesson 7 |

**Discretionary** access control lets each owner decide who else may use what they own. It is
flexible and it is how most file sharing works, and its weakness is in the name: it depends on
every owner's discretion, and owners share generously and forget to unshare. Lesson 6's privilege
creep grows here.

**Mandatory** access control takes the decision away from owners. Every resource and every person
carries a label, and a central policy compares them; even the owner of a file cannot give it to
somebody whose label does not allow it. It is strict and hard to run, which is why it lives where
the cost of a leak justifies it. A form of it also appears inside operating systems, as SELinux and
AppArmor, which confine what programs may do whatever their owners say.

**Role-based** access control gives permissions to roles, and roles to people. When bruno joins
finance, he is added to `hr` and receives everything `hr` may do; when he moves, he is removed and
loses it. That makes lesson 6's joiners, movers and leavers far easier, because one change to one
person's roles is the whole job. Its weakness is **role explosion**: an organisation that creates a
new role for every exception ends up with more roles than people.

**Attribute-based** access control writes rules over any attribute: the user's department, the
resource's sensitivity, the device's state, the time, the place. It is the most expressive and the
one Zero Trust needs, because "who, from what device, in what context" is a rule about attributes.
Its weakness is that the rules can become hard to read, and a rule nobody can read is a rule nobody
can check.

### The portal's rule, classified

The portal says: *you may read a payslip if it is yours, or if you are in `hr`*. The second half is
pure RBAC. The first half compares an attribute of the user (the name) with an attribute of the
resource (whose payslip it is), which is a small piece of ABAC. Two models in one line is the
normal case.
