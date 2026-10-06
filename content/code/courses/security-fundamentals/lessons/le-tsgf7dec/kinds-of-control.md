---
title: Kinds of control
version: 1
---

Layers say **where** a control sits. Two more classifications say **what it does** and **what it is
made of**, and a defence that uses only one kind is thinner than its number of layers suggests.

### By what it does

| function | what it does | at the shop |
|---|---|---|
| **preventive** | stops the incident from happening | a password on the portal, a firewall rule |
| **detective** | notices that it is happening or has happened | the portal's log, an alert on repeated failures |
| **corrective** | limits the damage and restores normal | restoring from backup, revoking a leaked password |
| **deterrent** | discourages an attempt | a warning banner, a visible camera |
| **compensating** | stands in for a control that cannot be used | extra logging on an old system that cannot have MFA |

Beginners design almost entirely in the first row. **Prevention alone assumes it never fails**,
which section 02 of this lesson said is false. A defence with no detective controls fails silently:
the attacker who got past the password is never noticed. A defence with no corrective controls
notices and cannot recover. The shop's portal has a preventive control (the login), a detective one
(the log, which the next section shows) and a corrective one (changing a leaked password);
take any of the three away and the gap is obvious.

### By what it is made of

| nature | also called | examples |
|---|---|---|
| **administrative** | managerial, procedural | policies, training, background checks, the risk register |
| **technical** | logical | passwords, encryption, firewalls, file permissions |
| **physical** | | locks, badges, guards, fire suppression |

The two tables cross. A visitor book is a physical, detective control; an acceptable use policy is
an administrative, deterrent one; disk encryption is a technical, preventive one. Laying the shop's
controls out in a grid of function against nature is a quick way to find a whole column or row
that is empty, which is where the next incident usually comes from.

**A compensating control deserves a word.** Sometimes the right control cannot be applied: an old
machine runs software that does not support MFA, and replacing it is a year away. The answer is
not to give up on the risk but to add something that covers the same weakness another way, such as
restricting who can reach the machine and watching its logins closely. The compensation is written
in the risk register with the reason and a date, exactly as an acceptance would be, because it is a
temporary arrangement rather than a design.
