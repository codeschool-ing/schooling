---
title: The attack that asks to be let in
version: 1
---

Every control so far has been about packets. **Phishing is about a person**: a message crafted so that
somebody inside opens a document, types a password into the wrong page, or approves a payment. It
arrives through the front door, addressed to a real employee, and it works because the firewall is
right to let e-mail and web pages through.

**Social engineering** is the wider family: a phone call from "IT support" asking for a code, a
message from "the director" asking for an urgent transfer, a USB stick left in the car park. What they
share is that the attacker borrows authority, urgency or helpfulness, and the person does the rest.

The network sees the consequences, not the conversation, and they fall into a pattern worth
recognising:

| stage | what happens | what the network can see |
|---|---|---|
| delivery | a message with a link or an attachment | the mail gateway's verdict; a lookup of an unusual name |
| the first click | a page asks for a password, or a document runs code | a connection to a name nobody in the company visited before |
| a foothold | software on the laptop contacts whoever sent it | regular connections to one outside address, at odd hours |
| spreading | the software reaches other machines inside | a workstation connecting to other workstations, on file sharing or remote desktop |
| the payoff | files encrypted, or data copied out | a sudden surge of writes to a file server, or of uploads |

**Ransomware** is the payoff that made this pattern famous: software that encrypts every file it can
reach and demands payment for the key, often after copying the data out to threaten publication as
well. It rarely stops at one machine, because the machine where it starts is almost never the one
holding what matters.

Nothing in this lesson stops a person from clicking. What it does is shorten each stage: a name that
does not resolve, a neighbour that does not answer, a machine that can be cut off in seconds, and
backups that the software cannot reach.
