---
title: The law, and the data DLP itself collects
version: 1
---

**In Brazil the reason to know where personal data is is a law, the LGPD** (Lei Geral de Proteção de
Dados, Law 13.709 of 2018), and the authority that enforces it is the ANPD. Two of its principles
change what a DLP project is for.

**Necessity**, which the law calls *necessidade*: a firm may hold only the personal data its
purpose needs. That turns the scanner of this lesson from a guard into a question. Twenty client
cards in a spreadsheet on a workstation are a finding before anybody tries to send them anywhere:
why does an accounting firm keep card numbers in a file at all? The cheapest data to protect is the
data deleted on the day nobody needed it, which is lesson 1's argument about services, applied to
records.

**Security**, *segurança*: the firm must take technical and administrative measures to protect the
data from unauthorised access and from accidental or unlawful loss. DLP is one of those measures,
and the law also requires that a security incident which may cause relevant risk or damage to the
people concerned is reported to the ANPD and to them. Knowing which files held what is how a firm
answers the first question the authority asks after a laptop is lost: whose data was on it.

## Watching the staff is processing their data

**A DLP tool reads what employees send.** Its logs say who copied which file, when, and to where,
and that record is personal data about the employees, under the same law. It does not make DLP
unlawful; it makes it something with rules of its own:

- **Tell people.** Monitoring that staff are not told about is hard to justify under any principle
  of the law, and it also loses the main effect DLP has, which is that people who know a rule is
  there stop making the mistake.
- **Keep it proportionate.** The guard of this lesson reads one folder and keeps a count and a
  masked example. A tool that kept a copy of every file every employee sent would hold a second
  copy of everything the firm wants protected, and all of their private mail besides.
- **Limit who reads the logs, and for how long they are kept.** A DLP log is a list of the firm's
  most sensitive files and who touched them, which makes it one of the files most worth protecting.

None of this is legal advice, and the text of the law and the ANPD's guidance are where a real
deployment starts. What the lesson can show is the engineering side of the same idea, and it
already has: the scanner counts and masks, the guard holds rather than deletes, and the network
rule knows destinations rather than contents. Each is the least the job needs.
