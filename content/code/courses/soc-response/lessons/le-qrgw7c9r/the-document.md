---
title: The postmortem document
version: 1
---

The review is written up in a **postmortem document**, and it is a different thing from lesson 20's incident
report. The report is for people outside the response, management, clients, sometimes a regulator, and it
explains. The postmortem is for the people who run the systems, and it changes things. Its parts:

| part | what goes in it |
|---|---|
| **summary** | three sentences: what happened, the impact, the main factors |
| **timeline** | lesson 12's, corrected by what the review learned |
| **numbers** | the intervals from `milestones.sql` |
| **what went well** | detection in one minute; containment in 33 minutes after declaring; evidence collected before every change |
| **contributing factors** | written blamelessly, as in the third section |
| **actions** | the table from the previous section, with owners and dates |
| **open questions** | what is still not known, such as which files were in the 612 MB |

**"What went well" is not decoration.** A review that lists only failures teaches the team that the review is
a punishment, and it hides what to keep: Thursday's rule caught the login within a minute, and the next build
of the SIEM must not lose that by accident.

The document is written in the same blameless language as the meeting, it is shared with everybody who took
part before it is final, and it is kept with the incident record. A year later, when somebody asks why `gw`
refuses passwords, the answer is a link.
