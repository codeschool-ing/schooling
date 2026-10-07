---
title: The plan: decisions made in advance
version: 1
---

An **incident response plan** is a short document that records decisions so they do not have to be made
under pressure. Most plans that fail do so not because they are wrong but because they are long, unread,
and silent on the one decision that mattered. What a plan has to settle:

| the plan says | Thursday's question it answers |
|---|---|
| **what counts as an incident**, and the severity scale | is a successful login after guessing an incident, and how severe? |
| **who leads**, by role, with a deputy | who is in charge at nine in the morning? |
| **who may authorise what**: disconnecting a server, disabling an account, calling the police | may ana take `files` offline, or does the partner have to? |
| **who must be told, and when**: management, legal, the data protection officer | when does the company's lawyer hear about client files leaving? |
| **how people are reached** when the normal channels may be compromised | if email is not trusted, how do they talk? |
| **external contacts**: the insurer, an incident response firm on retainer, CERT.br, the ANPD | who outside helps, and who outside must be informed? |
| **where evidence is kept** and by whom | where do lesson 3's hashed logs and lesson 16's images go? |

The third row is the one most often left out and most often regretted. **Authority to act has to be
delegated before the incident**: an analyst who has to find a director to approve isolating a server at
two in the morning will either wait, and lose hours, or act without authority, and be blamed for the
outage. The plan says which actions the person leading the response may take alone.

Keep the plan **short enough to read during an incident**, version it, give it an owner, and review it at
least once a year and after every significant incident.
