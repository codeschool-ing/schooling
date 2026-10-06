---
title: How the frameworks fit together
version: 1
---

By now the course has named several frameworks, and they can look like rivals. They are not. Each
answers a different question, and organisations combine them.

| | question it answers | form | certifiable? | lesson |
|---|---|---|---|---|
| **ISO/IEC 27001** | how do we manage information security as a system? | requirements for a management system | **yes** | 14 |
| **ISO/IEC 27002** | how do we implement each control? | guidance on 93 controls | no | 14 |
| **NIST CSF 2.0** | what outcomes should our programme achieve, and where are we? | 6 functions, 22 categories, 106 outcomes | no | this one |
| **NIST RMF (SP 800-37)** | how do we take one system from design to authorised operation? | a seven-step process | no (an authorization, not a certificate) | this one |
| **NIST SP 800-53** | which controls, in full detail? | a catalogue of controls in 20 families | no | this one |
| **CIS Controls** | what should we do first, in what order? | 18 prioritised controls | no | 16 |

### A typical combination

A company of a few hundred people might use them like this: the **CSF** to talk to its board, because
six functions and a current and target profile fit on one slide; **ISO 27001** as the management system,
certified because customers ask for it; **27002** and the **CIS Controls** to decide and implement the
controls; and **SP 800-53** as a reference when a control needs a precise specification. A US federal
contractor would add the **RMF** for each system it operates on the government's behalf.

### The bridges between them

The frameworks were written to be mapped onto each other:

- NIST publishes informative references from each CSF subcategory to ISO 27001 controls, CIS
  Controls and SP 800-53;
- ISO 27002:2022 tags every control with the five original CSF functions as an attribute (lesson 14);
- the CIS Controls publish their own mappings to the CSF and to ISO 27001.

So the work of lesson 13's control mapping is mostly done already: an organisation that has implemented
a control for one framework can look up which outcomes of the others it satisfies.

### Choosing for the shop

For the shop, the CSF's six functions are the right **map**: one page that shows the owners where the
gaps are, written in words they already use. The **CIS Controls** of the next lesson are the right **to-do
list**, because they say what to do first. ISO 27001 waits until a customer asks, as lesson 14 advised.
The RMF does not apply to the shop at all, and its two ideas worth taking, categorise by impact and have
a named person authorise, are already in lessons 1 and 3.
