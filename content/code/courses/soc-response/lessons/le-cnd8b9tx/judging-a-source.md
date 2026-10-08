---
title: How much to believe it, and who may see it
version: 1
---

An indicator in a report is a claim made by somebody. Three questions decide how much it is worth before
it goes near a rule:

- **Is it relevant?** An address that attacks banks' payment systems says little to an accounting firm.
- **Is it current?** Every indicator has a life. A report should say when it stops being valid, and an
  expired indicator should leave the SIEM rather than linger in it.
- **How sure is the source, and how good is its record?** STIX carries a `confidence` from 0 to 100 on each
  object. Many teams also grade the source and the information separately with the **Admiralty system**:
  the source from **A** (completely reliable) to **F** (cannot be judged), and the information from **1**
  (confirmed by other sources) to **6** (truth cannot be judged). A "B2" is a usually reliable source
  saying something probably true.

Who may see a report is decided by the **Traffic Light Protocol**, maintained by FIRST. Version 2.0, in use
since 2022, has five labels:

| label | may be shared with |
|---|---|
| **TLP:RED** | only the people it was given to, by name, in the meeting or message |
| **TLP:AMBER+STRICT** | your own organisation only |
| **TLP:AMBER** | your organisation, and its clients who need it to protect themselves |
| **TLP:GREEN** | your wider community, but not posted publicly |
| **TLP:CLEAR** | anybody (it replaced TLP:WHITE) |

The label belongs to the person who wrote the report, and **receiving a report is accepting its label**.
Pasting a TLP:AMBER report into a public ticket or a vendor's support chat breaks the trust that made the
report possible, and sharing groups remove members who do it.
